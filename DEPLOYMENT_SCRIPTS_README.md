# Automated Deployment Scripts

This directory contains automated scripts to deploy and manage your Azure infrastructure. These scripts handle the complete deployment lifecycle including base infrastructure, SSL certificates, container images, and Application Gateway configuration.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Available Scripts](#available-scripts)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [What Gets Deployed](#what-gets-deployed)
- [Troubleshooting](#troubleshooting)
- [Cost Estimates](#cost-estimates)

---

## Overview

These scripts automate the complete deployment of:

✅ **Base Layer (100_base)**
- Virtual Network and Subnets
- Key Vault with Managed Identity
- Application Gateway Subnet
- Public IP for Application Gateway
- Log Analytics & Application Insights

✅ **SSL Certificate**
- Self-signed certificate generation (for testing)
- Automatic upload to Key Vault
- Managed Identity permissions

✅ **Backend Layer (400_backend)**
- Azure Container Registry (ACR)
- Container App Environment
- Container App with sample API
- Application Gateway (Standard_v2)

✅ **Sample API**
- Flask-based REST API
- Docker image build and push to ACR
- Multiple test endpoints
- Health monitoring

---

## Prerequisites

Before running these scripts, ensure you have the following installed:

### Required Tools

| Tool | Version | Installation Link | Check Command |
|------|---------|------------------|---------------|
| **Azure CLI** | Latest | [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) | `az --version` |
| **Terraform** | 1.0+ | [Download](https://www.terraform.io/downloads) | `terraform version` |
| **Docker** | Latest | [Docker Desktop](https://www.docker.com/products/docker-desktop) | `docker --version` |
| **OpenSSL** | Latest | Included with Git Bash on Windows | `openssl version` |

### Azure Requirements

- Active Azure subscription
- Appropriate permissions to create resources
- Azure CLI logged in: `az login`
- Correct subscription selected: `az account set --subscription <subscription-id>`

### System Requirements

- **Windows**: PowerShell 5.1 or later (PowerShell 7+ recommended)
- **Linux/Mac**: Bash shell
- **Disk Space**: At least 2GB free for Docker images and logs
- **Network**: Stable internet connection for Azure API calls

---

## Available Scripts

### 1. Deployment Scripts

#### Windows (PowerShell)
```powershell
.\deploy-infrastructure.ps1
```
- **Platform**: Windows 10/11, Windows Server
- **Shell**: PowerShell 5.1+
- **Features**: Full deployment automation with colored output

#### Linux/Mac (Bash)
```bash
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh
```
- **Platform**: Linux, macOS, WSL, Git Bash
- **Shell**: Bash 4.0+
- **Features**: Full deployment automation with colored output

### 2. Cleanup Script

#### Windows (PowerShell)
```powershell
.\destroy-infrastructure.ps1
```
- **Destroys ALL deployed resources**
- **Requires confirmation** (type "DELETE")
- **Checks for orphaned resources**

---

## Quick Start

### Windows Quick Start

1. **Open PowerShell as Administrator**
   ```powershell
   cd D:\projects\terraform_v1\terraform
   ```

2. **Login to Azure**
   ```powershell
   az login
   az account set --subscription "<your-subscription-name-or-id>"
   ```

3. **Run Deployment Script**
   ```powershell
   .\deploy-infrastructure.ps1
   ```

4. **Wait for Completion** (approximately 15-20 minutes)

5. **Test Your Deployment**
   ```powershell
   # Get the public IP from the output and test
   curl -k https://<APPLICATION-GATEWAY-IP>/api/health
   ```

### Linux/Mac Quick Start

1. **Open Terminal**
   ```bash
   cd /path/to/terraform
   ```

2. **Login to Azure**
   ```bash
   az login
   az account set --subscription "<your-subscription-name-or-id>"
   ```

3. **Make Script Executable and Run**
   ```bash
   chmod +x deploy-infrastructure.sh
   ./deploy-infrastructure.sh
   ```

4. **Wait for Completion** (approximately 15-20 minutes)

5. **Test Your Deployment**
   ```bash
   # Get the public IP from the output and test
   curl -kL https://<APPLICATION-GATEWAY-IP>/api/health
   ```

---

## Detailed Usage

### Deployment Process Flow

The deployment script follows this sequence:

```
1. Prerequisites Check
   ├── Verify Azure CLI installed
   ├── Verify Terraform installed
   ├── Verify Docker installed
   ├── Verify OpenSSL installed
   └── Verify Azure login status

2. Deploy Base Layer
   ├── Initialize Terraform
   ├── Create Terraform plan
   ├── Apply infrastructure changes
   └── Output base layer resources

3. Setup SSL Certificate
   ├── Generate self-signed certificate
   ├── Convert to PFX format
   ├── Upload to Key Vault
   └── Configure permissions

4. Deploy Backend Layer
   ├── Initialize Terraform
   ├── Create Application Gateway
   ├── Create Container Apps
   └── Create ACR

5. Build and Deploy Sample API
   ├── Login to ACR
   ├── Build Docker image using ACR Build
   ├── Push image to ACR
   └── Restart Container App

6. Verify Deployment
   ├── Test API endpoints
   ├── Check backend health
   └── Verify SSL/TLS

7. Display Summary
   ├── Show public IP address
   ├── Show test commands
   └── Save deployment log
```

### Log Files

Each deployment creates a timestamped log file:

- **Format**: `deployment-YYYYMMDD-HHMMSS.log`
- **Location**: Current directory
- **Content**: Complete deployment output including all commands and responses
- **Use Case**: Troubleshooting, audit trail, debugging

Example:
```
deployment-20250130-143025.log
```

### Script Features

#### Automatic Error Handling
- **Exits on first error**: Prevents partial deployments
- **Detailed error messages**: Clear indication of what failed
- **Rollback guidance**: Instructions for manual cleanup if needed

#### Progress Tracking
- **Color-coded output**:
  - 🔵 **Blue (INFO)**: General information
  - 🟢 **Green (SUCCESS)**: Successful operations
  - 🟡 **Yellow (WARNING)**: Non-critical issues
  - 🔴 **Red (ERROR)**: Critical failures

- **Section headers**: Clear separation of deployment phases
- **Time tracking**: Shows total deployment duration

#### Validation Checks
- **Certificate existence**: Skips regeneration if already exists
- **Resource availability**: Verifies prerequisites before starting
- **Health checks**: Validates deployment success

---

## What Gets Deployed

### Resource Groups

| Resource Group | Purpose | Resources |
|----------------|---------|-----------|
| `ZTF-PROD-BASE` | Base infrastructure | VNet, Subnets, Key Vault, IPs |
| `ZTF-PROD-BACKEND` | Backend services | App Gateway, Container Apps |
| `ZTF-PROD-BACKEND-CA` | Container Apps | Container App Environment |

### Base Layer Resources

```yaml
Virtual Network:
  Name: ZTF-vnw-network-prod-eastus-001
  CIDR: 10.0.0.0/16
  Subnets:
    - Container Apps: 10.0.2.0/24
    - App Gateway: 10.0.4.0/24
    - Private Link: 10.0.3.0/24

Key Vault:
  Name: ZTF-PROD-SECRET
  Soft Delete: Enabled
  Managed Identity: Enabled
  Secrets: SSL certificate, app configs

Public IP:
  Name: ZTF-pip-prod-eastus-appgw-001
  Type: Static
  SKU: Standard

Log Analytics:
  Retention: 30 days
  Application Insights: Connected
```

### Backend Layer Resources

```yaml
Container Registry:
  Name: ztfacrregistoryprodeastus001
  SKU: Basic
  Admin: Enabled
  Images: sample-api:latest

Container App Environment:
  Name: ZTF-cae-environment-prod-eus-001
  Type: Consumption
  VNet: Integrated
  Monitoring: Application Insights

Container App:
  Name: ztf-cap-container-prod-eus-001
  CPU: 0.5 cores
  Memory: 1Gi
  Replicas: 1-4 (auto-scale)
  Port: 80
  External Access: Enabled

Application Gateway:
  Name: ZTF-apg-appgateway-prod-eus-001
  SKU: Standard_v2
  Capacity: 1 (Developer tier)
  Frontend:
    - HTTPS: Port 443 with SSL
    - HTTP: Port 80 (redirects to HTTPS)
  Backend:
    - Protocol: HTTP
    - Port: 80
    - Target: Container App FQDN
  Health Probe:
    - Protocol: HTTP
    - Path: /
    - Interval: 30 seconds
```

### Sample API Endpoints

After deployment, the following endpoints are available:

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/` | GET | Welcome message | JSON with API info |
| `/api/health` | GET | Health check | `{"status": "healthy"}` |
| `/api/test` | GET | Test data | Complex JSON structure |
| `/api/info` | GET | Service information | Version, environment |
| `/api/echo` | POST | Echo request body | Returns posted data |
| `/api/environment` | GET | Environment variables | System info |

---

## Testing Your Deployment

### Quick Health Check

```powershell
# Windows PowerShell
$IP = "<your-app-gateway-ip>"
Invoke-WebRequest -Uri "https://$IP/api/health" -SkipCertificateCheck

# Linux/Mac/Git Bash
IP="<your-app-gateway-ip>"
curl -kL https://$IP/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "sample-api",
  "timestamp": "2025-01-30T12:34:56.789012"
}
```

### Full API Test Suite

```bash
# Set the Application Gateway IP
export APP_GW_IP="<your-app-gateway-ip>"

# Test 1: Root endpoint
echo "Testing root endpoint..."
curl -kL https://$APP_GW_IP/

# Test 2: Health check
echo "Testing health endpoint..."
curl -kL https://$APP_GW_IP/api/health

# Test 3: Test data
echo "Testing test endpoint..."
curl -kL https://$APP_GW_IP/api/test

# Test 4: Service info
echo "Testing info endpoint..."
curl -kL https://$APP_GW_IP/api/info

# Test 5: Echo (POST)
echo "Testing echo endpoint..."
curl -kL https://$APP_GW_IP/api/echo \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Application Gateway!"}'

# Test 6: Environment
echo "Testing environment endpoint..."
curl -kL https://$APP_GW_IP/api/environment
```

### Backend Health Check

```bash
# Check Application Gateway backend health
az network application-gateway show-backend-health \
  --name ZTF-apg-appgateway-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0]"
```

Expected output:
```json
{
  "address": "ztf-cap-container-prod-eus-001.calmsky-848b0baf.eastus.azurecontainerapps.io",
  "health": "Healthy",
  "ipConfiguration": null
}
```

### Container App Logs

```bash
# View Container App logs
az containerapp logs show \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --follow

# View recent logs only
az containerapp logs show \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --tail 50
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Script Execution Policy (Windows)

**Error**: "cannot be loaded because running scripts is disabled on this system"

**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass (one-time)
PowerShell.exe -ExecutionPolicy Bypass -File .\deploy-infrastructure.ps1
```

#### Issue 2: Azure Login Required

**Error**: "Not logged into Azure"

**Solution**:
```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "<subscription-id-or-name>"

# Verify
az account show
```

#### Issue 3: Docker Not Running

**Error**: "Docker not found" or "Cannot connect to Docker daemon"

**Solution**:
```bash
# Windows: Start Docker Desktop
# Verify Docker is running
docker ps

# If Docker Desktop is not installed:
# Download from: https://www.docker.com/products/docker-desktop
```

#### Issue 4: Terraform State Lock

**Error**: "Error acquiring the state lock"

**Solution**:
```bash
# If state is genuinely stuck, force unlock
cd azure-terrafrom/layers/<layer>/env/prod
terraform force-unlock <lock-id>

# Then re-run the script
```

#### Issue 5: Backend Health Unhealthy

**Error**: Backend shows as "Unhealthy" in Application Gateway

**Solution**:
```bash
# Wait 2-3 minutes for Container App to fully start
# Check Container App logs
az containerapp logs show \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --tail 100

# Restart Container App if needed
az containerapp revision restart \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND

# Check health again after 2-3 minutes
az network application-gateway show-backend-health \
  --name ZTF-apg-appgateway-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND
```

#### Issue 6: SSL Certificate Upload Failed

**Error**: "Failed to upload certificate to Key Vault"

**Solution**:
```bash
# Verify Key Vault access
az keyvault show --name <key-vault-name>

# Check your permissions
az keyvault get-policy --name <key-vault-name>

# If access denied, have an admin grant you permissions:
az keyvault set-policy \
  --name <key-vault-name> \
  --upn <your-email@domain.com> \
  --certificate-permissions get list create import
```

#### Issue 7: ACR Build Failed

**Error**: "Failed to build/push sample API image"

**Solution**:
```bash
# Verify ACR exists and is accessible
az acr show --name <acr-name>

# Try building manually
cd azure-terrafrom/layers/400_backend/sample-api
az acr build --registry <acr-name> --image sample-api:latest .

# Check ACR login
az acr login --name <acr-name>
```

### Getting Help

If you encounter issues not covered here:

1. **Check the log file**: `deployment-YYYYMMDD-HHMMSS.log`
2. **Review detailed documentation**:
   - `azure-terrafrom/layers/400_backend/DEPLOYMENT_GUIDE.md`
   - `azure-terrafrom/layers/400_backend/FINAL_DEPLOYMENT_SUMMARY.md`
3. **Azure Portal**: Check resources manually in Azure Portal
4. **Terraform state**: Check state files in each layer

---

## Cost Estimates

### Monthly Cost Breakdown

| Resource | SKU/Tier | Quantity | Est. Cost (USD/month) |
|----------|----------|----------|----------------------|
| Container Registry | Basic | 1 | $5 |
| Container App Environment | Consumption | 1 | $0 (included) |
| Container App | Consumption | 1 | $20-30 |
| Application Gateway | Standard_v2 | 1 instance | $125-150 |
| Public IP | Standard, Static | 1 | $5 |
| Key Vault | Standard | 1 | $3 |
| Log Analytics | Pay-as-you-go | 1 | $5-10 |
| Application Insights | Pay-as-you-go | 1 | $0-5 |
| **Total** | | | **~$163-208/month** |

### Cost Optimization Tips

- **Developer/Test**: Current configuration is already optimized for dev/test
- **Production**: Consider increasing App Gateway capacity to 2+ for HA
- **Idle environments**: Use `destroy-infrastructure.ps1` when not in use
- **Container Apps**: Auto-scales to zero when no traffic (Consumption plan)
- **Monitoring**: Review and adjust Log Analytics retention period

---

## Destroying Infrastructure

When you're done testing or want to start fresh:

### ⚠️ WARNING: This deletes ALL resources!

```powershell
# Windows PowerShell
.\destroy-infrastructure.ps1

# You will be prompted to type "DELETE" to confirm
```

### What Gets Destroyed

- ✅ All Application Gateway resources
- ✅ All Container Apps and environments
- ✅ Container Registry and all images
- ✅ Virtual Network and subnets
- ✅ Key Vault and all secrets (soft-deleted, recoverable for 90 days)
- ✅ Public IPs
- ✅ Log Analytics workspace
- ✅ Application Insights

### Recovery

- **Key Vault**: Soft-deleted, can be recovered within 90 days
- **Other resources**: Cannot be recovered, must redeploy
- **Terraform state**: Remains in local `.terraform` directories

---

## Advanced Usage

### Custom Variables

To customize the deployment, edit the variables in:

- `azure-terrafrom/layers/100_base/env/prod/variables.tf`
- `azure-terrafrom/layers/400_backend/env/prod/variables.tf`

Example customizations:
- Change environment name (Env variable)
- Modify CIDR ranges
- Adjust Application Gateway capacity
- Change Container App replica counts

### Manual Deployment Steps

If you prefer to deploy manually:

```bash
# 1. Deploy base layer
cd azure-terrafrom/layers/100_base/env/prod
terraform init
terraform plan
terraform apply

# 2. Generate SSL certificate (see DEPLOYMENT_GUIDE.md)
# 3. Deploy backend layer
cd ../../400_backend/env/prod
terraform init
terraform plan
terraform apply

# 4. Build and push sample API (see DEPLOYMENT_GUIDE.md)
```

### Deploying to Different Environments

To deploy to UAT or other environments:

1. Create new environment directory:
   ```bash
   cp -r azure-terrafrom/layers/*/env/prod azure-terrafrom/layers/*/env/uat
   ```

2. Update variables in each `uat/variables.tf`:
   ```hcl
   variable "Env" {
     default = "uat"
   }
   ```

3. Update the deployment script to point to UAT directories

---

## Best Practices

### Before Deployment

- ✅ Verify you're logged into the correct Azure subscription
- ✅ Ensure you have Owner or Contributor permissions
- ✅ Review cost estimates
- ✅ Backup any existing configurations
- ✅ Review firewall/proxy settings if in corporate network

### During Deployment

- ✅ Monitor the script output for any warnings
- ✅ Don't interrupt the script (full deployment takes 15-20 minutes)
- ✅ Save the log file for troubleshooting
- ✅ Note the Application Gateway IP address from output

### After Deployment

- ✅ Test all API endpoints
- ✅ Verify backend health in Application Gateway
- ✅ Check Application Insights for telemetry
- ✅ Review generated documentation
- ✅ Set up monitoring alerts (optional)
- ✅ Replace self-signed certificate with valid SSL cert (for production)

---

## Security Considerations

### Current Security Features

- ✅ SSL/TLS termination at Application Gateway
- ✅ HTTPS enforced (HTTP auto-redirects)
- ✅ Managed Identity for Key Vault access
- ✅ ACR with admin credentials (for testing)
- ✅ VNet integration for Container Apps
- ✅ Application Insights monitoring

### Production Hardening Recommendations

- 🔒 Replace self-signed certificate with valid SSL from CA
- 🔒 Upgrade to WAF_v2 SKU for Web Application Firewall
- 🔒 Disable Container App external access (requires Private Link)
- 🔒 Use Managed Identity instead of ACR admin credentials
- 🔒 Configure NSGs for additional network security
- 🔒 Enable Azure DDoS Protection
- 🔒 Set up Azure Front Door for global distribution
- 🔒 Configure custom domain with proper DNS

---

## Additional Resources

### Documentation

- [DEPLOYMENT_GUIDE.md](azure-terrafrom/layers/400_backend/DEPLOYMENT_GUIDE.md) - Detailed Terraform guide
- [AZURE_PORTAL_GUIDE.md](azure-terrafrom/layers/400_backend/AZURE_PORTAL_GUIDE.md) - Manual portal deployment
- [FINAL_DEPLOYMENT_SUMMARY.md](azure-terrafrom/layers/400_backend/FINAL_DEPLOYMENT_SUMMARY.md) - Complete deployment summary
- [sample-api/README.md](azure-terrafrom/layers/400_backend/sample-api/README.md) - API documentation

### Azure Documentation

- [Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## Version History

- **v1.0.0** (2025-01-30): Initial release
  - PowerShell and Bash deployment scripts
  - Automated SSL certificate generation
  - Sample API deployment
  - Infrastructure destroy script
  - Comprehensive documentation

---

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review the deployment logs
3. Consult the detailed documentation
4. Check Azure Portal for resource status

---

**Last Updated**: January 30, 2025
**Maintained By**: DevOps Team
**Terraform Version**: 1.0+
**Azure Provider Version**: Latest
