# Quick Start Guide - Backend Infrastructure

## Current Status: ✓ Phase 1 Complete

Your Container App is **running privately** with the sample API!

---

## What's Working Now

✓ **Container App** - Running with private access only
✓ **Sample API** - Deployed with multiple test endpoints
✓ **ACR Image** - Built and pushed successfully
✓ **Private Access** - Container App NOT publicly accessible (secure)

### Container App Details:
```
Name: ztf-cap-container-prod-eus-001
Internal FQDN: ztf-cap-container-prod-eus-001.calmsky-848b0baf.eastus.azurecontainerapps.io
External Access: DISABLED (private only)
Status: Running
Image: sample-api:latest
```

---

## What You Need to Do Next

### To Enable Public Access via Application Gateway:

#### Step 1: Update Base Layer (Required)

Add these outputs to `azure-terrafrom/layers/100_base/env/prod/outputs.tf`:

```hcl
# Application Gateway Subnet
output "app_gateway_subnet_id" {
  value       = module.your_appgw_subnet.id
  description = "Subnet ID for Application Gateway"
}

# Public IP for Application Gateway
output "public_ip_id" {
  value       = module.your_public_ip.id
  description = "Public IP resource ID"
}

output "public_ip_address" {
  value       = module.your_public_ip.ip_address
  description = "Public IP address value"
}

# SSL Certificate from Key Vault
output "certificate_id" {
  value       = "https://your-keyvault.vault.azure.net/secrets/your-ssl-cert"
  description = "SSL certificate secret ID"
}
```

Apply base layer changes:
```bash
cd azure-terrafrom/layers/100_base/env/prod
terraform apply
```

#### Step 2: Deploy Application Gateway

Uncomment Application Gateway in `azure-terrafrom/layers/400_backend/env/prod/main.tf`:

```bash
cd azure-terrafrom/layers/400_backend/env/prod

# Edit main.tf and uncomment:
# - module "application_gateway_001"
# - module "firewall_policy_001"

# Edit outputs.tf and uncomment:
# - output "application_gateway_public_ip"

terraform plan
terraform apply
```

---

## Testing Your Deployment

### Test Container App is Private (Expected to Fail):
```bash
curl https://ztf-cap-container-prod-eus-001.calmsky-848b0baf.eastus.azurecontainerapps.io/
# Should return: "Error 404 - This Container App is stopped or does not exist"
```

### Check Container App Status:
```bash
az containerapp show \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --query "properties.provisioningState"
```

### View API Logs:
```bash
az containerapp logs show \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --follow
```

### After Application Gateway is Deployed:
```bash
# Get App Gateway Public IP
APP_GW_IP=$(terraform output -raw application_gateway_public_ip)

# Test API endpoints
curl -k https://${APP_GW_IP}/
curl -k https://${APP_GW_IP}/api/health
curl -k https://${APP_GW_IP}/api/info
curl -k https://${APP_GW_IP}/api/test
```

---

## Sample API Endpoints

Once Application Gateway is deployed, you can access:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Welcome message |
| `/api/health` | GET | Health check |
| `/api/info` | GET | Service information |
| `/api/test` | GET | Test endpoint with sample data |
| `/api/echo` | POST | Echo request body |
| `/api/environment` | GET | Environment variables |

---

## Architecture Diagrams

### Current Architecture (Phase 1):
```
Internet ✗ (No Access)
    ↓
Container App (Private)
├── Internal FQDN only
├── Sample API running
└── 2 gunicorn workers
```

### Target Architecture (Phase 2 - After App Gateway):
```
Internet → Application Gateway (Public IP)
              ↓ SSL/TLS
          WAF Protection
          Health Probes
              ↓
    Container App (Private)
    ├── Accessible only via App Gateway
    └── Sample API running
```

---

## Quick Commands Reference

### Container App Management:
```bash
# Show container app details
az containerapp show --name ztf-cap-container-prod-eus-001 --resource-group ZTF-PROD-BACKEND

# List replicas
az containerapp replica list --name ztf-cap-container-prod-eus-001 --resource-group ZTF-PROD-BACKEND

# Update to new image
az containerapp update \
  --name ztf-cap-container-prod-eus-001 \
  --resource-group ZTF-PROD-BACKEND \
  --image ztfacrregistoryprodeastus001.azurecr.io/sample-api:v2.0
```

### ACR Management:
```bash
# List repositories
az acr repository list --name ztfacrregistoryprodeastus001

# Show tags
az acr repository show-tags --name ztfacrregistoryprodeastus001 --repository sample-api

# Build new image
cd azure-terrafrom/layers/400_backend/sample-api
az acr build --registry ztfacrregistoryprodeastus001 --image sample-api:latest .
```

### Terraform Commands:
```bash
cd azure-terrafrom/layers/400_backend/env/prod

# Check current state
terraform state list

# Show outputs
terraform output

# Plan changes
terraform plan

# Apply changes
terraform apply
```

---

## Troubleshooting

### Container App Not Starting:
1. Check logs: `az containerapp logs show ...`
2. Verify image exists in ACR
3. Check ACR credentials in secrets

### Image Pull Errors:
```bash
# Enable ACR admin
az acr update --name ztfacrregistoryprodeastus001 --admin-enabled true

# Get credentials
az acr credential show --name ztfacrregistoryprodeastus001
```

### Terraform Errors:
1. Run `terraform init` if modules changed
2. Check remote state is accessible
3. Verify Azure CLI is logged in: `az account show`

---

## Documentation Files

📄 **DEPLOYMENT_GUIDE.md** - Complete Terraform deployment instructions
📄 **AZURE_PORTAL_GUIDE.md** - Manual Azure Portal setup guide
📄 **IMPLEMENTATION_SUMMARY.md** - Detailed implementation summary
📄 **QUICK_START.md** - This file
📄 **sample-api/README.md** - Sample API documentation

---

## Cost Summary

**Current (Phase 1)**: ~$25-35/month
- Container Registry (Basic): $5
- Container App (Consumption): $20-30

**After App Gateway (Phase 2)**: ~$155-190/month
- Everything above +
- Application Gateway (Standard_v2): $125-150
- Public IP (Standard): $5

---

## Security Checklist

- ✓ Container App not publicly accessible
- ✓ ACR credentials secured
- ✓ Key Vault integration for secrets
- ✓ Managed Identity enabled
- ⏳ SSL/TLS termination (pending App Gateway)
- ⏳ WAF protection (pending App Gateway)

---

## Getting Help

1. **Check logs first**: Container App logs usually show the issue
2. **Review documentation**: Detailed guides available
3. **Verify infrastructure**: Use `az` commands to check resource status
4. **Check Terraform state**: `terraform state list` and `terraform show`

---

## Summary

**Status**: ✓ **Phase 1 Complete**

**What You Have**:
- Private Container App running sample API
- Secure infrastructure (no public access)
- Production-ready modules
- Comprehensive documentation

**Next Steps**:
1. Add outputs to base layer
2. Deploy Application Gateway
3. Test end-to-end connectivity

**Estimated Time to Complete**: 30-60 minutes (mostly waiting for Azure deployments)

---

**Last Updated**: December 30, 2025
**Version**: 1.0.0
