# Backend Infrastructure Deployment Guide

## Overview

This guide covers deploying the backend infrastructure layer which includes:
- **Azure Container Registry (ACR)** - For storing container images
- **Azure Container Apps** - For running containerized applications
- **Application Gateway** - For routing external traffic to Container Apps
- **Private Endpoint Integration** - Securing Container Apps from public access

## Architecture

```
Internet → Application Gateway (Public IP) → Container App (Internal/Private)
                    ↓
            SSL Termination
            WAF Protection
            Load Balancing
```

### Key Features:
- Container Apps are **NOT** publicly accessible (external_enabled = false)
- All traffic routes through Application Gateway
- Developer tier Application Gateway (Standard_v2 with capacity 1)
- SSL/TLS termination at Application Gateway
- Health probes configured for high availability

---

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   ```

2. **Terraform** installed (v1.0+)
   ```bash
   terraform --version
   ```

3. **Base Layer Deployed** (Layer 100_base must be deployed first)
   - Virtual Network with subnets
   - Log Analytics Workspace
   - Key Vault with required secrets
   - User Assigned Managed Identity
   - Public IP for Application Gateway
   - SSL Certificate in Key Vault

4. **Required Base Layer Outputs**:
   - `log_analytics_id`
   - `container_app_subnet_id`
   - `app_gateway_subnet_id`
   - `public_ip_id`
   - `public_ip_address`
   - `identity_id`
   - `identity_client_id`
   - `key_vault_id`
   - `certificate_id`
   - `application_insight_connection_string`
   - `application_insight_id`
   - `application_insight_instrumentation_key`

---

## Deployment Steps

### Step 1: Navigate to Backend Layer

```bash
cd D:\projects\terraform_v1\terraform\azure-terrafrom\layers\400_backend\env\prod
```

### Step 2: Review and Update Variables

Edit `variables.tf` or create a `terraform.tfvars` file:

```hcl
Env             = "prod"
subscription_id = "your-subscription-id"
rg_name         = "INFRA-PROD-BACKEND"
rg_location     = "eastus"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download required provider plugins
- Initialize the backend state
- Configure remote state references to base layer

### Step 4: Review Deployment Plan

```bash
terraform plan -out=backend.tfplan
```

Review the plan carefully. You should see:
- 1 Azure Container Registry
- 1 Container App Environment
- 1 Container App (with external_enabled = false)
- 1 Application Gateway (Standard_v2, capacity 1)
- 1 Firewall Policy

### Step 5: Apply Infrastructure

```bash
terraform apply backend.tfplan
```

Deployment takes approximately **15-20 minutes**.

### Step 6: Capture Outputs

```bash
terraform output
```

Save these values:
- `acr_login_server` - ACR server URL
- `acr_name` - ACR admin username
- `container_app_name` - Container App name
- `container_app_fqdn` - Internal FQDN
- `application_gateway_public_ip` - Public IP for testing

---

## Deploy Sample API to Container App

### Option 1: Using Docker and Azure CLI

#### Step 1: Create a Simple Test API

Create a directory for your sample API:

```bash
mkdir sample-api
cd sample-api
```

Create `app.py`:

```python
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Welcome to Sample API",
        "status": "healthy",
        "version": "1.0.0"
    })

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/info')
def info():
    return jsonify({
        "environment": os.getenv("Common__environment", "unknown"),
        "service": "sample-api",
        "endpoints": ["/", "/api/health", "/api/info", "/api/test"]
    })

@app.route('/api/test')
def test():
    return jsonify({
        "message": "Test endpoint working",
        "data": {"key": "value"}
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

Create `requirements.txt`:

```txt
Flask==3.0.0
gunicorn==21.2.0
```

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 80

CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "2", "app:app"]
```

#### Step 2: Build and Push to ACR

```bash
# Get ACR credentials from Terraform output
ACR_NAME=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_name)
ACR_PASSWORD=$(terraform output -raw acr_password)

# Login to ACR
az acr login --name ${ACR_NAME%.*}

# Build the image
docker build -t sample-api:latest .

# Tag the image
docker tag sample-api:latest ${ACR_NAME}/sample-api:latest

# Push to ACR
docker push ${ACR_NAME}/sample-api:latest
```

#### Step 3: Update Container App

The Container App will automatically pull the new image. If needed, trigger a revision:

```bash
CONTAINER_APP_NAME=$(terraform output -raw container_app_name)
RESOURCE_GROUP="INFRA-PROD-BACKEND"

az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image ${ACR_NAME}/sample-api:latest
```

### Option 2: Using ACR Tasks (Build in Cloud)

```bash
ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)

# Build directly in ACR
az acr build \
  --registry $ACR_NAME \
  --image sample-api:latest \
  --file Dockerfile \
  .
```

---

## Testing the Deployment

### Test 1: Verify Container App is NOT Publicly Accessible

```bash
CONTAINER_APP_FQDN=$(terraform output -raw container_app_fqdn)

# This should FAIL or timeout (as expected - private access only)
curl https://${CONTAINER_APP_FQDN}
```

Expected: Connection timeout or refused (Container App has external_enabled = false)

### Test 2: Test via Application Gateway

```bash
APP_GATEWAY_IP=$(terraform output -raw application_gateway_public_ip)

# Test health endpoint
curl -k https://${APP_GATEWAY_IP}/

# Test specific API endpoints
curl -k https://${APP_GATEWAY_IP}/api/health
curl -k https://${APP_GATEWAY_IP}/api/info
curl -k https://${APP_GATEWAY_IP}/api/test
```

Expected: All requests should succeed with 200 OK responses

### Test 3: Verify Application Gateway Health

```bash
RESOURCE_GROUP="INFRA-PROD-BACKEND"
APP_GATEWAY_NAME="INFRA-apg-appgateway-prod-eus-001"

# Check backend health
az network application-gateway show-backend-health \
  --name $APP_GATEWAY_NAME \
  --resource-group $RESOURCE_GROUP
```

Expected: Backend pool should show "Healthy" status

---

## Architecture Details

### Container App Configuration

- **External Access**: Disabled (external_enabled = false)
- **Ingress**: Internal only
- **Target Port**: 80
- **CPU**: 0.5 cores
- **Memory**: 1Gi
- **Scaling**: 1-4 replicas (CPU threshold: 70%)
- **Environment**: Consumption-based

### Application Gateway Configuration

- **SKU**: Standard_v2 (Developer tier)
- **Capacity**: 1 instance
- **Frontend**: Public IP with SSL/TLS
- **Backend Pool**: Container App internal FQDN
- **Health Probe**: HTTPS on / path (60s interval)
- **Routing**:
  - Port 443 (HTTPS) → Container App
  - Port 80 (HTTP) → Redirect to HTTPS

### Security Features

1. **No Public Container Access**: Container Apps only accessible via Application Gateway
2. **SSL/TLS Termination**: At Application Gateway level
3. **WAF Ready**: Firewall policy configured (can be upgraded to WAF_v2)
4. **Managed Identity**: For secure access to Key Vault and ACR
5. **Health Monitoring**: Application Insights integration

---

## Troubleshooting

### Issue: Application Gateway shows unhealthy backend

**Solution**:
1. Check Container App is running:
   ```bash
   az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP
   ```

2. Check Container App logs:
   ```bash
   az containerapp logs show \
     --name $CONTAINER_APP_NAME \
     --resource-group $RESOURCE_GROUP \
     --follow
   ```

3. Verify health probe path returns 200 OK

### Issue: Cannot access Application Gateway

**Solution**:
1. Verify public IP is assigned:
   ```bash
   az network public-ip show \
     --name "INFRA-pip-publicip-prod-eus-001" \
     --resource-group "INFRA-PROD-BASE"
   ```

2. Check NSG rules on Application Gateway subnet

3. Verify SSL certificate is valid in Key Vault

### Issue: Container fails to pull image from ACR

**Solution**:
1. Verify ACR admin is enabled:
   ```bash
   az acr update --name $ACR_NAME --admin-enabled true
   ```

2. Check Container App has ACR credentials configured

3. Verify Managed Identity has AcrPull role on ACR

### Issue: Terraform apply fails with dependency errors

**Solution**:
1. Ensure base layer (100_base) is deployed
2. Verify remote state configuration in `data.tf`
3. Check all required outputs exist in base layer state

---

## Updating the Infrastructure

### Update Container App Image

```bash
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image ${ACR_NAME}/your-app:new-version
```

### Scale Container App

```bash
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --min-replicas 2 \
  --max-replicas 10
```

### Upgrade Application Gateway to WAF

Edit `main.tf`:
```hcl
sku = "WAF_v2"
capacity = 2  # WAF requires min 2 instances
```

Then apply:
```bash
terraform plan
terraform apply
```

---

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will delete:
- Container Registry and all images
- Container Apps and environments
- Application Gateway
- All data will be lost

---

## Cost Optimization

### Developer/Test Environment:
- Application Gateway: Standard_v2, Capacity 1
- Container App: Consumption plan
- Estimated: ~$100-150/month

### Production Environment:
- Application Gateway: WAF_v2, Capacity 2
- Container App: Dedicated plan
- Estimated: ~$300-500/month

---

## Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Application Gateway Documentation](https://learn.microsoft.com/azure/application-gateway/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Azure Portal logs
3. Contact your Azure administrator
