# API Management Deployment Guide

## Overview

This guide covers the deployment of Azure API Management with Container Apps backend integration. The architecture uses API Management Developer tier to expose and manage APIs backed by Azure Container Apps with internal ingress.

## Architecture

```
Internet --> API Management (Developer_1) --> Container App (Internal) --> Backend Services
                                                   |
                                                   v
                                            Application Insights
```

### Key Components

1. **API Management (Developer_1 SKU)**
   - Developer tier for testing and development
   - Integrated with Application Insights for logging
   - Managed identity for secure access to resources

2. **Container App (Internal Ingress)**
   - Set to `external_enabled = false` for internal-only access
   - Only accessible via API Management
   - Connected to VNet subnet for private connectivity

3. **Integration**
   - API Management connects to Container App via internal FQDN
   - All requests proxied through API Management
   - Centralized logging and monitoring

## Prerequisites

Before deploying, ensure you have:

1. **Subscription Updated**: New subscription ID `5d5e0746-817a-49c6-b53d-bc26d8bc1850` configured
2. **Base Layer Deployed**: Layer 100_base must be deployed first
3. **Database Layer Deployed**: Layer 300_database must be deployed
4. **Storage Layer Deployed**: Layer 200_tenant_storage must be deployed
5. **Azure CLI**: Logged in with appropriate permissions
6. **Terraform**: Version 1.5+ installed

## Deployment Steps

### 1. Initialize Terraform

Navigate to the backend layer:

```bash
cd azure-terrafrom/layers/400_backend/env/prod
```

Initialize Terraform (this will configure the backend):

```bash
terraform init
```

### 2. Review the Plan

Generate and review the execution plan:

```bash
terraform plan -out=apim.tfplan
```

Review the plan to ensure:
- API Management with Developer_1 SKU will be created
- Container App is configured with `external_enabled = false`
- Backend and API resources will be created in API Management
- All dependencies are resolved correctly

### 3. Apply the Configuration

Apply the Terraform plan:

```bash
terraform apply apim.tfplan
```

This will create:
- Azure API Management instance (Developer tier)
- API Management Logger (Application Insights integration)
- Backend pointing to Container App
- API with wildcard operation for proxying all requests
- Policy to route traffic to the backend

### 4. Verify Deployment

After deployment, verify the resources:

```bash
# Get outputs
terraform output

# Check API Management
az apim show --name <api-management-name> --resource-group INFRA-PROD-BACKEND

# Check Container App
az containerapp show --name <container-app-name> --resource-group INFRA-PROD-BACKEND-CA
```

### 5. Test the API

Get the API Management gateway URL from outputs:

```bash
terraform output api_management_gateway_url
```

Test the API endpoint:

```bash
# Replace <gateway-url> with the actual URL from outputs
curl https://<gateway-url>/api/health
```

## Configuration Details

### API Management Module Configuration

Location: `azure-terrafrom/layers/400_backend/env/prod/main.tf:207-220`

```hcl
module "api_management" {
  source = "../../modules/api_management"
  Env = var.Env
  rg_name = var.rg_name
  rg_location = var.rg_location
  publisher_name = "Tech Support"
  publisher_email = "tech@ztaegis.com"
  sku_name = "Developer_1"
  application_insights_id = data.terraform_remote_state.base.outputs.application_insight_id
  application_insights_key = data.terraform_remote_state.base.outputs.application_insight_instrumentation_key
  identity_id = [data.terraform_remote_state.base.outputs.identity_id]
  counts = "001"
  backend_url = module.container_app_001.host
}
```

### Container App Configuration

Location: `azure-terrafrom/layers/400_backend/env/prod/main.tf:41`

```hcl
external_enabled = false  # Internal access only - accessible via API Management
```

## API Management Features

### Backend Configuration

The API Management backend is configured to connect to the Container App:

- **Protocol**: HTTP
- **URL**: Container App internal FQDN
- **Description**: Backend for Container App

### API Configuration

- **Name**: container-app-api
- **Path**: /api
- **Protocols**: HTTPS only
- **Subscription Required**: false (for testing)

### Wildcard Operation

A wildcard operation (`/*`) proxies all requests to the backend:

- **Method**: * (all HTTP methods)
- **URL Template**: /* (all paths)
- **Policy**: Routes to container-app-backend

## Post-Deployment Tasks

### 1. Configure Custom Domain (Optional)

```bash
az apim update --name <api-management-name> \
  --resource-group INFRA-PROD-BACKEND \
  --set hostnameConfigurations[0].hostName=api.yourdomain.com
```

### 2. Enable Subscription Keys (Production)

For production, enable subscription keys:

1. Navigate to API Management in Azure Portal
2. Go to APIs > container-app-api
3. Settings > Subscription required: Enable
4. Create subscriptions for clients

### 3. Configure Rate Limiting

Add rate limiting policies in Azure Portal:

1. Navigate to API Management > APIs
2. Select container-app-api
3. Inbound processing > Add policy
4. Configure rate-limit-by-key or quota-by-key

### 4. Monitor Performance

View metrics and logs:

```bash
# API Management metrics
az monitor metrics list --resource <api-management-resource-id> \
  --metric "Requests" "Capacity"

# Application Insights logs
az monitor app-insights query --app <app-insights-name> \
  --analytics-query "requests | where timestamp > ago(1h)"
```

## Troubleshooting

### Container App Not Accessible

If API Management cannot reach the Container App:

1. Verify Container App is running:
   ```bash
   az containerapp show --name <container-app-name> --resource-group INFRA-PROD-BACKEND-CA
   ```

2. Check Container App ingress configuration:
   ```bash
   az containerapp ingress show --name <container-app-name> --resource-group INFRA-PROD-BACKEND-CA
   ```

3. Verify VNet integration (Container App Environment should be in the same VNet)

### API Management Provisioning Failed

If API Management fails to provision:

1. Check subscription quota:
   ```bash
   az apim check-name --name <proposed-name>
   ```

2. Verify all required resources (Key Vault, Application Insights) are accessible

3. Check Azure service health for API Management service

### Backend Connection Errors

If you get 502/504 errors:

1. Verify backend URL is correct in API Management
2. Check Container App logs:
   ```bash
   az containerapp logs show --name <container-app-name> --resource-group INFRA-PROD-BACKEND-CA
   ```
3. Test Container App health endpoint directly from VNet

## Clean Up

To destroy the resources:

```bash
cd azure-terrafrom/layers/400_backend/env/prod
terraform destroy
```

**Warning**: This will destroy all resources including Container App, API Management, and Container Registry. Make sure to backup any data before proceeding.

## Cost Considerations

### Developer Tier Pricing

- **API Management Developer**: ~$50-60/month
- **Container Apps**: Pay for vCPU and memory usage
- **Application Insights**: Pay for data ingestion
- **Container Registry Basic**: ~$5/month

### Production Upgrade

For production, consider upgrading to:
- **API Management**: Standard or Premium tier (VNet injection, multi-region)
- **Container Apps**: Dedicated workload profiles for guaranteed capacity

## Next Steps

1. Deploy sample API to Container Registry
2. Test API endpoints through API Management
3. Configure authentication and authorization policies
4. Set up CI/CD pipeline for automated deployments
5. Configure monitoring and alerting

## Support

For issues or questions:
- Review Terraform state: `terraform show`
- Check Azure Portal for resource status
- Review Application Insights for errors and performance metrics
- Contact Tech Support: tech@ztaegis.com
