# Azure Portal Manual Deployment Guide

## Backend Infrastructure Setup (Without Terraform)

This guide walks you through manually creating the backend infrastructure in Azure Portal.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Create Container Registry](#step-1-create-container-registry)
3. [Create Container App Environment](#step-2-create-container-app-environment)
4. [Deploy Container App](#step-3-deploy-container-app)
5. [Create Application Gateway](#step-4-create-application-gateway)
6. [Configure Private Access](#step-5-configure-private-access)
7. [Deploy Sample Application](#step-6-deploy-sample-application)
8. [Testing](#step-7-testing)

---

## Prerequisites

Before starting, ensure you have:

1. **Azure Subscription** with appropriate permissions
2. **Resource Groups** created:
   - `ZTF-PROD-BASE` (for base infrastructure)
   - `ZTF-PROD-BACKEND` (for backend services)
3. **Base Infrastructure** (from Layer 100):
   - Virtual Network with subnets
   - Log Analytics Workspace
   - Key Vault with secrets
   - User Assigned Managed Identity
   - Public IP address
   - SSL Certificate stored in Key Vault

---

## Step 1: Create Container Registry

### 1.1 Navigate to Container Registry

1. Go to [Azure Portal](https://portal.azure.com)
2. Click **"+ Create a resource"**
3. Search for **"Container Registry"**
4. Click **"Create"**

### 1.2 Configure Basic Settings

- **Subscription**: Select your subscription
- **Resource Group**: `ZTF-PROD-BACKEND`
- **Registry Name**: `ztfacrprodeus001` (must be globally unique)
- **Location**: `East US`
- **SKU**: `Basic` (for dev/test) or `Standard` (for production)

### 1.3 Configure Networking

- **Public Access**: Enable (for pushing images)
- **Private Endpoint**: Can be configured later for enhanced security

### 1.4 Configure Encryption

- **Encryption**: Leave as default (Microsoft-managed keys)

### 1.5 Review and Create

1. Click **"Review + Create"**
2. Click **"Create"**
3. Wait 2-3 minutes for deployment

### 1.6 Enable Admin User

1. Go to your Container Registry
2. Navigate to **"Settings"** → **"Access keys"**
3. Enable **"Admin user"**
4. Save **Username** and **Password** (needed later)

---

## Step 2: Create Container App Environment

### 2.1 Navigate to Container Apps

1. In Azure Portal, click **"+ Create a resource"**
2. Search for **"Container App Environment"**
3. Click **"Create"**

### 2.2 Configure Basics

- **Subscription**: Select your subscription
- **Resource Group**: Create new: `ZTF-PROD-BACKEND-CA`
- **Environment Name**: `ztf-cae-environment-prod-eus-001`
- **Region**: `East US`

### 2.3 Configure Monitoring

- **Log Analytics Workspace**: Select existing from base layer
  - Example: `ZTF-log-workspace-prod-eus-001`

### 2.4 Configure Networking

- **Use your own virtual network**: Yes
- **Virtual Network**: Select existing VNet from base layer
- **Infrastructure Subnet**: Select Container App subnet
  - Example: `container-app-subnet`
- **Internal only**: No (will configure at Container App level)

### 2.5 Configure Workload Profile

- **Workload Profile**: `Consumption`
- **Zone Redundancy**: Disabled (for dev/test)

### 2.6 Review and Create

1. Click **"Review + Create"**
2. Click **"Create"**
3. Wait 5-10 minutes for deployment

---

## Step 3: Deploy Container App

### 3.1 Navigate to Container Apps

1. Click **"+ Create a resource"**
2. Search for **"Container App"**
3. Click **"Create"**

### 3.2 Configure Basics

- **Subscription**: Select your subscription
- **Resource Group**: `ZTF-PROD-BACKEND`
- **Container App Name**: `ztf-cap-container-prod-eus-001`
- **Region**: `East US`
- **Container App Environment**: Select the environment created in Step 2

### 3.3 Configure Container

- **Use quickstart image**: Uncheck
- **Name**: `ztf-cap-container-prod-eus-001`
- **Image source**: `Azure Container Registry`
- **Registry**: Select your ACR from Step 1
- **Image**: `sample-api` (will be pushed later)
- **Tag**: `latest`
- **Registry Authentication**: Managed Identity or Admin credentials

**OR** start with a test image:
- **Use quickstart image**: Check
- **Image**: `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest`

### 3.4 Configure Resources

- **CPU**: `0.5` cores
- **Memory**: `1 Gi`

### 3.5 Configure Ingress

**IMPORTANT**: This is where we configure private access

- **Ingress**: Enabled
- **Ingress Traffic**:
  - **Accepting traffic from**: `Limited to Container Apps Environment` ⚠️
  - This ensures the Container App is NOT publicly accessible
- **Target Port**: `80`
- **Transport**: `HTTP`

### 3.6 Configure Scaling

- **Min Replicas**: `1`
- **Max Replicas**: `4`
- **Scale Rule**:
  - **Type**: `CPU`
  - **Threshold**: `70`%

### 3.7 Configure Identity

1. Go to **"Identity"** tab
2. **User Assigned Identity**: Add
3. Select the managed identity from base layer
   - Example: `ZTF-identity-prod-eus-001`

### 3.8 Configure Secrets

Navigate to **"Secrets"** and add:

1. **acr-password**
   - Value: ACR admin password from Step 1.6

2. **database-endpoint**
   - Key Vault Reference: Link to Key Vault secret

3. **database-key**
   - Key Vault Reference: Link to Key Vault secret

4. **jwt-key**
   - Key Vault Reference: Link to Key Vault secret

(Add all other required secrets from Key Vault)

### 3.9 Configure Environment Variables

Navigate to **"Environment Variables"** and add:

| Name | Type | Value/Secret |
|------|------|--------------|
| `CosmosDb__AccountEndpoint` | Secret | database-endpoint |
| `CosmosDb__AccountKey` | Secret | database-key |
| `CosmosDb__DatabaseName` | Plain | ZTF-uat-db |
| `Common__environment` | Plain | Production |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Plain | From base layer |

### 3.10 Review and Create

1. Click **"Review + Create"**
2. Click **"Create"**
3. Wait 3-5 minutes for deployment

### 3.11 Note the Internal FQDN

1. Go to your Container App
2. Navigate to **"Overview"**
3. Copy the **"Application URL"** (internal FQDN)
   - Example: `ztf-cap-container-prod-eus-001.internal.xxxxx.eastus.azurecontainerapps.io`
4. Save this for Application Gateway configuration

---

## Step 4: Create Application Gateway

### 4.1 Navigate to Application Gateway

1. Click **"+ Create a resource"**
2. Search for **"Application Gateway"**
3. Click **"Create"**

### 4.2 Configure Basics

- **Subscription**: Select your subscription
- **Resource Group**: `ZTF-PROD-BACKEND`
- **Application Gateway Name**: `ZTF-apg-appgateway-prod-eus-001`
- **Region**: `East US`
- **Tier**: `Standard V2` (for developer tier)
- **Enable Autoscaling**: No
- **Instance Count**: `1` (developer tier)
- **Availability Zone**: None (for dev/test)
- **HTTP2**: Enabled

### 4.3 Configure Virtual Network

- **Virtual Network**: Select existing VNet from base layer
- **Subnet**: Select Application Gateway subnet
  - Example: `app-gateway-subnet`
  - **Note**: Must be a dedicated subnet for App Gateway only

### 4.4 Configure Frontends

- **Frontend IP Address Type**: Public
- **Public IP Address**: Select existing public IP from base layer
  - Example: `ZTF-pip-publicip-prod-eus-001`

### 4.5 Configure Backends

Click **"Add a backend pool"**:

- **Name**: `backend-pool-containerapp`
- **Add backend pool without targets**: No
- **Target Type**: `FQDN`
- **Target**: Paste the Container App internal FQDN from Step 3.11
  - Example: `ztf-cap-container-prod-eus-001.internal.xxxxx.eastus.azurecontainerapps.io`
- Click **"Add"**

### 4.6 Configure Routing Rules

#### 4.6.1 Create HTTPS Listener

Click **"Add a routing rule"**:

**Listener Tab**:
- **Rule Name**: `https-rule`
- **Priority**: `1`
- **Listener Name**: `https-listener`
- **Frontend IP**: Public
- **Protocol**: HTTPS
- **Port**: `443`
- **Listener Type**: Basic
- **Error page URL**: No

**SSL Certificate**:
- **Choose a certificate**: Upload new or use Key Vault
- **Cert Name**: `ssl-certificate`
- **Key Vault Certificate**: Select certificate from Key Vault
  - Requires Managed Identity with Key Vault access

**Backend Targets Tab**:
- **Target Type**: Backend pool
- **Backend Target**: `backend-pool-containerapp`
- **Backend Settings**: Create new (see below)

#### 4.6.2 Create Backend Settings

In the **Backend Settings** section:

- **Backend Settings Name**: `backend-https-settings`
- **Backend Protocol**: `HTTPS`
- **Backend Port**: `443`
- **Cookie-based Affinity**: Disabled
- **Connection Draining**: Disabled
- **Request Timeout**: `60` seconds
- **Override backend path**: Leave empty
- **Override with new hostname**: Yes
- **Pick hostname from backend target**: Yes
- **Create custom probe**: Yes

#### 4.6.3 Create Health Probe

In **Custom Probe** section:

- **Probe Name**: `health-probe`
- **Protocol**: HTTPS
- **Pick hostname from backend settings**: Yes
- **Path**: `/`
- **Interval**: `60` seconds
- **Timeout**: `5` seconds
- **Unhealthy Threshold**: `3`
- **Use probe matching conditions**: Yes
- **Status Codes**: `200-250`

Click **"Add"** to save the routing rule.

#### 4.6.4 Create HTTP to HTTPS Redirect

Click **"Add a routing rule"** again:

**Listener Tab**:
- **Rule Name**: `http-redirect-rule`
- **Priority**: `2`
- **Listener Name**: `http-listener`
- **Frontend IP**: Public
- **Protocol**: HTTP
- **Port**: `80`

**Backend Targets Tab**:
- **Target Type**: Redirection
- **Redirection Type**: Permanent
- **Redirection Target**: Listener
- **Target Listener**: `https-listener`

Click **"Add"**

### 4.7 Configure Managed Identity

1. Navigate to **"Identity"** tab
2. **User Assigned**: Add
3. Select the managed identity from base layer
   - This is needed for accessing Key Vault certificate

### 4.8 Configure WAF Policy (Optional)

1. Navigate to **"Web Application Firewall"** tab
2. Click **"Create new policy"**
3. **Name**: `ZTF-waf-policy-prod-001`
4. **Policy State**: Enabled
5. **Policy Mode**: Detection (or Prevention for production)
6. **Rule Set**: OWASP 3.2
7. Click **"OK"**

### 4.9 Review and Create

1. Click **"Review + Create"**
2. Review all settings carefully
3. Click **"Create"**
4. Wait 15-20 minutes for deployment

---

## Step 5: Configure Private Access

### 5.1 Verify Container App is Private

1. Go to your Container App
2. Navigate to **"Ingress"**
3. Verify **"Ingress Traffic"** is set to:
   - `Limited to Container Apps Environment` or `Limited to vNet`
4. Try accessing the Container App URL directly - it should NOT be accessible from internet

### 5.2 Test Application Gateway Connectivity

1. Go to Application Gateway
2. Navigate to **"Backend Health"**
3. Wait 2-3 minutes for health probe to run
4. Verify backend pool shows **"Healthy"** status

**If Unhealthy**:
- Check Container App is running
- Verify health probe path returns 200 OK
- Check Container App logs
- Verify FQDN in backend pool is correct

---

## Step 6: Deploy Sample Application

### 6.1 Prepare Sample Application

On your local machine:

1. Create a directory for the sample API
2. Create `app.py`:

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Welcome to Sample API", "status": "healthy"})

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/info')
def info():
    return jsonify({
        "service": "sample-api",
        "endpoints": ["/", "/api/health", "/api/info", "/api/test"]
    })

@app.route('/api/test')
def test():
    return jsonify({"message": "Test endpoint working"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

3. Create `requirements.txt`:

```txt
Flask==3.0.0
gunicorn==21.2.0
```

4. Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 80
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "2", "app:app"]
```

### 6.2 Build and Push to ACR

Open terminal/command prompt:

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Login to ACR
az acr login --name ztfacrprodeus001

# Build and push image
docker build -t sample-api:latest .
docker tag sample-api:latest ztfacrprodeus001.azurecr.io/sample-api:latest
docker push ztfacrprodeus001.azurecr.io/sample-api:latest
```

### 6.3 Update Container App

#### Option A: Via Azure Portal

1. Go to your Container App
2. Navigate to **"Containers"** or **"Revision Management"**
3. Click **"Create new revision"**
4. Update **Image**: `ztfacrprodeus001.azurecr.io/sample-api:latest`
5. Click **"Create"**

#### Option B: Via Azure CLI

```bash
az containerapp update \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --image ztfacrprodeus001.azurecr.io/sample-api:latest
```

### 6.4 Verify Deployment

1. Go to Container App → **"Revision Management"**
2. Check new revision is active and traffic is 100%
3. Go to **"Log stream"** to see application logs

---

## Step 7: Testing

### 7.1 Get Application Gateway Public IP

1. Go to your Application Gateway
2. Navigate to **"Frontend IP configurations"**
3. Click on the public IP configuration
4. Copy the **"IP address"**

### 7.2 Test via Browser

Open browser and navigate to:
- `https://<APP_GATEWAY_PUBLIC_IP>/`
- `https://<APP_GATEWAY_PUBLIC_IP>/api/health`
- `https://<APP_GATEWAY_PUBLIC_IP>/api/info`
- `https://<APP_GATEWAY_PUBLIC_IP>/api/test`

**Note**: You may see a certificate warning if using self-signed cert.

### 7.3 Test via cURL/PowerShell

**cURL (Linux/Mac/Git Bash)**:
```bash
curl -k https://<APP_GATEWAY_PUBLIC_IP>/
curl -k https://<APP_GATEWAY_PUBLIC_IP>/api/health
curl -k https://<APP_GATEWAY_PUBLIC_IP>/api/info
curl -k https://<APP_GATEWAY_PUBLIC_IP>/api/test
```

**PowerShell**:
```powershell
Invoke-WebRequest -Uri "https://<APP_GATEWAY_PUBLIC_IP>/" -SkipCertificateCheck
Invoke-WebRequest -Uri "https://<APP_GATEWAY_PUBLIC_IP>/api/health" -SkipCertificateCheck
```

### 7.4 Verify Container App is Private

Try accessing Container App directly (should FAIL):

```bash
curl https://ztf-cap-container-prod-eus-001.internal.xxxxx.eastus.azurecontainerapps.io/
```

Expected: Connection timeout or refused (as expected - private access only)

### 7.5 Check Backend Health

1. Go to Application Gateway
2. Navigate to **"Backend health"**
3. Verify all backends show **"Healthy"** status
4. Check response times and error counts

### 7.6 View Metrics

**Container App Metrics**:
1. Go to Container App → **"Metrics"**
2. View: Requests, Replica Count, CPU Usage, Memory Usage

**Application Gateway Metrics**:
1. Go to Application Gateway → **"Metrics"**
2. View: Total Requests, Failed Requests, Response Status, Backend Health

---

## Troubleshooting

### Issue: Application Gateway Backend Unhealthy

**Solutions**:

1. **Check Container App is Running**:
   - Go to Container App → Overview
   - Verify status is "Running"
   - Check replica count > 0

2. **Check Health Probe Configuration**:
   - Go to Application Gateway → Health probes
   - Verify probe path returns 200 OK
   - Check protocol (HTTPS), port (443), and hostname settings

3. **Check Container App Logs**:
   - Go to Container App → Log stream
   - Look for errors or startup issues

4. **Verify Network Connectivity**:
   - Ensure Container App subnet allows traffic from App Gateway subnet
   - Check NSG rules on both subnets

### Issue: Cannot Access Application Gateway

**Solutions**:

1. **Check Public IP**:
   - Verify Public IP is assigned to Application Gateway
   - Check IP is not blocked by firewall

2. **Check NSG Rules**:
   - Verify Application Gateway subnet NSG allows inbound 443 and 80
   - Verify required App Gateway management ports are open

3. **Check Listeners**:
   - Verify listeners are configured correctly
   - Check SSL certificate is valid

### Issue: SSL Certificate Errors

**Solutions**:

1. **Verify Certificate in Key Vault**:
   - Ensure certificate is uploaded to Key Vault
   - Check certificate is not expired

2. **Check Managed Identity**:
   - Verify App Gateway has Managed Identity assigned
   - Ensure identity has "Get" and "List" permissions on Key Vault

3. **Upload Certificate Directly**:
   - As alternative, upload .pfx certificate directly to App Gateway

### Issue: Container App Cannot Pull Image

**Solutions**:

1. **Check ACR Admin**:
   - Verify ACR admin user is enabled
   - Verify credentials are correct in Container App secrets

2. **Check Managed Identity**:
   - Ensure Container App identity has AcrPull role on ACR

3. **Verify Image Exists**:
   - Check image is pushed to ACR
   - Verify tag is correct

---

## Monitoring and Maintenance

### Enable Diagnostic Logs

**Application Gateway**:
1. Go to Application Gateway → **"Diagnostic settings"**
2. Click **"Add diagnostic setting"**
3. Select: Access Log, Performance Log, Firewall Log
4. Send to: Log Analytics Workspace

**Container App**:
1. Go to Container App → **"Diagnostic settings"**
2. Click **"Add diagnostic setting"**
3. Select: Container App Console Logs, System Logs
4. Send to: Log Analytics Workspace

### Set Up Alerts

**Application Gateway Alerts**:
- Unhealthy Host Count > 0
- Failed Requests > threshold
- Response Time > threshold

**Container App Alerts**:
- Replica Count = 0
- CPU Usage > 80%
- Memory Usage > 80%
- Restart Count > threshold

---

## Cost Considerations

### Development Environment:
- **Container Registry**: ~$5/month (Basic)
- **Container App**: ~$20-30/month (Consumption)
- **Application Gateway**: ~$125-150/month (Standard_v2, 1 instance)
- **Total**: ~$150-185/month

### Production Environment:
- **Container Registry**: ~$20/month (Standard)
- **Container App**: ~$50-100/month (Dedicated or Consumption)
- **Application Gateway**: ~$250-300/month (WAF_v2, 2 instances)
- **Total**: ~$320-420/month

### Cost Optimization Tips:
1. Use Consumption plan for Container Apps when possible
2. Set appropriate auto-scaling limits
3. Use Standard_v2 (not WAF_v2) for non-production
4. Use Basic ACR for development
5. Stop/deallocate resources when not in use (dev/test only)

---

## Next Steps

1. **Configure Custom Domain**:
   - Add custom domain to Application Gateway
   - Update DNS records
   - Add SSL certificate for custom domain

2. **Enable WAF**:
   - Upgrade to WAF_v2 for production
   - Configure OWASP rules
   - Set up custom WAF rules

3. **Set Up CI/CD**:
   - Configure Azure DevOps pipelines
   - Automate image builds and deployments
   - Implement blue-green deployments

4. **Enhance Monitoring**:
   - Set up Application Insights
   - Create dashboards in Azure Monitor
   - Configure alerts and notifications

5. **Implement Backup**:
   - Backup Container Registry images
   - Document configuration
   - Test disaster recovery procedures

---

## Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Application Gateway Documentation](https://learn.microsoft.com/azure/application-gateway/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)

---

## Summary

You have successfully deployed:
- Azure Container Registry for storing images
- Container App Environment with Consumption plan
- Container App with private access only (not publicly accessible)
- Application Gateway with SSL/TLS termination
- Sample API application with multiple test endpoints

All traffic now flows through the Application Gateway, providing a secure and scalable architecture for your containerized applications.
