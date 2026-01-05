# Azure API Management with Private Container Apps

## Overview

This guide documents the implementation of Azure API Management (APIM) in External mode with private Azure Container Apps connectivity. The architecture ensures that APIM is publicly accessible while Container Apps remain private and only accessible through APIM within the VNet.

## Architecture

```
Internet
   │
   ↓
[APIM - External Mode]
Public IP: 48.194.32.30
Private IP: 10.0.5.4 (VNet)
   │
   ↓ (Private VNet Connection)
   │
[Container App Environment - Internal]
   │
   ↓
[Container App - Private]
Static IP: 10.0.2.251
```

### Key Components

1. **API Management (APIM)**
   - SKU: Developer
   - Mode: External (publicly accessible with VNet injection)
   - Public Gateway: `https://ztf-api-apimanagement-prod-eastus-001-v2.azure-api.net`
   - VNet Subnet: `10.0.5.0/24` (api-management)
   - Public IP: `48.194.32.30`
   - Private VNet IP: `10.0.5.4`

2. **Container App Environment**
   - Configuration: Internal load balancer enabled
   - Public Network Access: Disabled
   - VNet Subnet: `10.0.2.0/24` (container-app)
   - Default Domain: `yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io`
   - Static IP: `10.0.2.251`

3. **Container App**
   - External Ingress: Enabled (but still private due to internal environment)
   - FQDN: `ztf-cap-container-prod-eus-001.yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io`
   - Protocol: HTTPS
   - Status: NOT publicly accessible (only via APIM)

4. **Private DNS Zone**
   - Zone: `yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io`
   - Wildcard A Record: `*` → `10.0.2.251`
   - VNet Link: Enabled

5. **Network Security Group (NSG)**
   - Applied to APIM subnet
   - Allows: ApiManagement service tag (port 3443)
   - Allows: Azure Load Balancer
   - Allows: HTTPS from Internet
   - Allows: Azure Infrastructure outbound

## Implementation Steps

### 1. Base Layer Setup (100_base)

**Created APIM Subnet:**
```hcl
module "apim_subnet" {
  source      = "../../modules/subnet"
  Env         = var.Env
  subnet_name = "api-management"
  subnet_cidr = "10.0.5.0/24"
  rg_location = var.rg_location
  v_net_name  = module.virtual_network.name
  rg_name     = var.rg_name
  delegation  = false
}
```

**Created NSG for APIM:**
```hcl
resource "azurerm_network_security_group" "apim_nsg" {
  name                = "ZTF-nsg-apim-prod-eastus-001"
  location            = var.rg_location
  resource_group_name = var.rg_name

  # Allow APIM Management Endpoint
  security_rule {
    name                       = "AllowAPIManagement"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Allow HTTPS from Internet
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Infrastructure Communication
  security_rule {
    name                       = "AllowAzureInfrastructure"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "12000-13000"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }
}

resource "azurerm_subnet_network_security_group_association" "apim_nsg_association" {
  subnet_id                 = module.apim_subnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}
```

### 2. APIM Module Configuration

**Updated APIM module to support VNet injection:**
```hcl
# modules/api_management/main.tf
resource "azurerm_api_management" "api_management" {
  name                = "ZTF-api-apimanagement-${var.Env}-eastus-${var.counts}-v2"
  location            = var.rg_location
  resource_group_name = var.rg_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  virtual_network_type = var.virtual_network_type  # External mode

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != "None" && var.subnet_id != null ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = var.identity_id
  }
}
```

**Added VNet configuration variables:**
```hcl
# modules/api_management/variables.tf
variable "virtual_network_type" {
  type        = string
  description = "The type of virtual network configuration (None, External, Internal)"
  default     = "None"
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID for VNet injection"
  default     = null
}

variable "backend_url" {
  type        = string
  description = "The URL of the backend Container App"
  default     = null
}
```

### 3. Container App Environment Configuration

**Updated module to support internal load balancer:**
```hcl
# modules/container_environment/main.tf
resource "azurerm_container_app_environment" "app_enviornment" {
  name                               = "ZTF-cae-appenv-${var.Env}-${var.rg_location}-${var.counts}"
  location                           = var.rg_location
  resource_group_name                = var.rg_name
  log_analytics_workspace_id         = var.log_analytics_id
  infrastructure_subnet_id           = var.subnet_id
  infrastructure_resource_group_name = var.new_rg
  internal_load_balancer_enabled     = var.internal_load_balancer_enabled
  public_network_access              = var.internal_load_balancer_enabled ? "Disabled" : "Enabled"

  workload_profile {
    name                  = var.workload_profile_type
    workload_profile_type = var.workload_profile_type
  }
}
```

**Added internal load balancer variable:**
```hcl
# modules/container_environment/variables.tf
variable "internal_load_balancer_enabled" {
  type        = bool
  description = "Enable internal load balancer for private Container Apps"
  default     = false
}
```

### 4. Backend Layer Configuration

**Final working configuration:**
```hcl
# env/prod/main.tf

# Container App Environment with internal load balancer
module "container_app_environment_001" {
  source                         = "../../modules/container_environment"
  Env                            = var.Env
  counts                         = "001"
  rg_name                        = var.rg_name
  rg_location                    = var.rg_location
  log_analytics_id               = data.terraform_remote_state.base.outputs.log_analytics_id
  subnet_id                      = data.terraform_remote_state.base.outputs.container_app_subnet_id
  new_rg                         = "${var.rg_name}-CA"
  workload_profile_type          = "Consumption"
  internal_load_balancer_enabled = true  # Enable internal load balancer
}

# Container App with external ingress (but still private due to internal environment)
module "container_app_001" {
  source             = "../../modules/container_app"
  Env                = var.Env
  counts             = "001"
  rg_name            = var.rg_name
  acr_password       = module.container_registry_001.admin_password
  acr_username       = module.container_registry_001.admin_username
  acr_server         = module.container_registry_001.login_server
  container_cpu      = "0.5"
  container_memory   = "1Gi"
  max_replicas       = 4
  min_replicas       = 1
  location           = var.rg_location
  identity_ids       = [data.terraform_remote_state.base.outputs.identity_id]
  container_port     = 80
  image              = "kennethreitz/httpbin:latest"
  app_environment_id = module.container_app_environment_001.id
  external_enabled   = true  # Enable ingress (still private due to internal environment)

  container_secrets = [
    {
      name  = "acr-password"
      value = module.container_registry_001.admin_password
    }
  ]

  environment_variable = []
}

# API Management with External mode and VNet injection
module "api_management" {
  source                   = "../../modules/api_management"
  Env                      = var.Env
  rg_name                  = var.rg_name
  rg_location              = var.rg_location
  publisher_name           = "Tech Support"
  publisher_email          = "tech@ztaegis.com"
  sku_name                 = "Developer_1"
  application_insights_id  = data.terraform_remote_state.base.outputs.application_insight_id
  application_insights_key = data.terraform_remote_state.base.outputs.application_insight_instrumentation_key
  identity_id              = [data.terraform_remote_state.base.outputs.identity_id]
  counts                   = "001"
  backend_url              = "ztf-cap-container-prod-eus-001.yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io"
  virtual_network_type     = "External"  # External mode - publicly accessible
  subnet_id                = data.terraform_remote_state.base.outputs.apim_subnet_id
}
```

### 5. Private DNS Configuration

**Created Private DNS zone for Container Apps:**
```bash
# Create Private DNS zone
az network private-dns zone create \
  --resource-group ZTF-PROD-MISC \
  --name yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io

# Link DNS zone to VNet
az network private-dns link vnet create \
  --resource-group ZTF-PROD-MISC \
  --zone-name yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io \
  --name container-app-link \
  --virtual-network ZTF-vnw-network-prod-eastus-001 \
  --registration-enabled false

# Create wildcard A record
az network private-dns record-set a create \
  --resource-group ZTF-PROD-MISC \
  --zone-name yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io \
  --name "*" \
  --ttl 300

# Add IP address to record
az network private-dns record-set a add-record \
  --resource-group ZTF-PROD-MISC \
  --zone-name yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io \
  --record-set-name "*" \
  --ipv4-address 10.0.2.251
```

## Key Challenges and Solutions

### Challenge 1: Double Isolation Issue

**Problem:** Initial configuration with `internal_load_balancer_enabled=true` on Container App Environment AND `external_enabled=false` on Container App created a double-isolation that prevented access even from APIM within the VNet.

**Solution:** Changed Container App to `external_enabled=true` while keeping the environment internal. This allows the Container App to be accessible within the VNet but not from the public internet.

### Challenge 2: Public Network Access Restriction

**Problem:** Azure requires `public_network_access` to be explicitly disabled when `internal_load_balancer_enabled` is true.

**Solution:** Added conditional configuration:
```hcl
public_network_access = var.internal_load_balancer_enabled ? "Disabled" : "Enabled"
```

### Challenge 3: HTTPS Redirection

**Problem:** Container Apps automatically redirect HTTP to HTTPS, causing issues when APIM was configured to use HTTP.

**Solution:** Updated APIM backend configuration to use HTTPS:
```hcl
url = "https://${var.backend_url}"
```

### Challenge 4: DNS Resolution

**Problem:** APIM couldn't resolve Container App's internal FQDN within the VNet.

**Solution:** Created Private DNS zone with wildcard A record pointing to Container App Environment's static IP and linked it to the VNet.

## Verification

### Test Container App is Private

```bash
# Should timeout (NOT accessible from internet)
curl https://ztf-cap-container-prod-eus-001.yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io/get
```

### Test APIM Can Access Container App

```bash
# Should return 200 OK
curl https://ztf-api-apimanagement-prod-eastus-001-v2.azure-api.net/api/get

# Check the origin - should show APIM's private VNet IP (10.0.5.4)
curl https://ztf-api-apimanagement-prod-eastus-001-v2.azure-api.net/api/ip
# Returns: {"origin": "223.178.213.73,10.0.5.4"}
```

## Available Endpoints

All endpoints are accessible through APIM's public gateway:

```bash
# Base URL
APIM_URL="https://ztf-api-apimanagement-prod-eastus-001-v2.azure-api.net"

# Test endpoints
curl $APIM_URL/api/get          # Returns GET request data
curl $APIM_URL/api/ip           # Returns origin IP
curl $APIM_URL/api/headers      # Returns request headers
curl $APIM_URL/api/user-agent   # Returns user agent
curl $APIM_URL/api/uuid         # Returns UUID
curl $APIM_URL/api/status/200   # Returns HTTP 200
curl $APIM_URL/api/delay/2      # Delays response by 2 seconds
curl $APIM_URL/api/html         # Returns HTML page
curl $APIM_URL/api/json         # Returns JSON
curl $APIM_URL/api/xml          # Returns XML
```

## Network Flow

```
1. User Request
   ↓
   Internet → APIM Public IP (48.194.32.30)

2. APIM Processing
   ↓
   APIM External Mode (VNet injected in 10.0.5.0/24)
   Private IP: 10.0.5.4

3. DNS Resolution
   ↓
   Private DNS Zone resolves:
   *.yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io → 10.0.2.251

4. Backend Connection
   ↓
   APIM Private IP (10.0.5.4) → Container App (10.0.2.251)
   Protocol: HTTPS

5. Response
   ↓
   Container App → APIM → User
```

## Resource Dependencies

```
VNet (10.0.0.0/16)
├── APIM Subnet (10.0.5.0/24)
│   ├── NSG (APIM rules)
│   └── APIM (External mode)
│
├── Container App Subnet (10.0.2.0/24)
│   └── Container App Environment (Internal)
│       └── Container App (Private)
│
└── Private DNS Zone
    └── *.yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io → 10.0.2.251
```

## Deployment Order

1. **Base Layer (100_base)**
   - VNet and subnets
   - APIM subnet and NSG
   - Private DNS zone (created manually)

2. **Backend Layer (400_backend)**
   - Container Registry
   - Container App Environment (internal)
   - Container App (with external ingress)
   - APIM (External mode with VNet injection)

3. **DNS Configuration** (manual)
   - Create Private DNS zone
   - Link to VNet
   - Create wildcard A record

## Cost Considerations

- **APIM Developer SKU**: ~$50/month (suitable for development)
- **Container Apps**: Pay-per-use (minimal cost for low traffic)
- **VNet**: No additional cost
- **Private DNS Zone**: ~$0.50/month

## Security Best Practices

1. ✅ Container Apps are not publicly accessible
2. ✅ APIM uses HTTPS for backend communication
3. ✅ NSG restricts traffic to APIM subnet
4. ✅ Public network access disabled on internal environment
5. ✅ Managed identities used for authentication
6. ✅ Application Insights enabled for monitoring

## Troubleshooting

### Issue: APIM returns 500 error

**Cause:** DNS resolution failing or Container App not reachable

**Solution:**
1. Verify Private DNS zone is created and linked to VNet
2. Check wildcard A record points to correct static IP
3. Verify Container App is running: `az containerapp show --name <app-name> --resource-group <rg-name>`

### Issue: Container App is publicly accessible

**Cause:** Environment not configured as internal

**Solution:**
1. Check `internal_load_balancer_enabled = true`
2. Verify `public_network_access = "Disabled"`
3. Recreate Container App Environment if needed

### Issue: NSG blocking APIM traffic

**Cause:** Missing required NSG rules

**Solution:**
Ensure NSG allows:
- ApiManagement service tag on port 3443
- AzureLoadBalancer
- HTTPS (443)
- Azure Infrastructure outbound

## Monitoring

**Check APIM diagnostics:**
```bash
az monitor app-insights query \
  --app <app-insights-name> \
  --resource-group <rg-name> \
  --analytics-query "requests | where timestamp > ago(1h) | summarize count() by resultCode"
```

**Check Container App logs:**
```bash
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg-name> \
  --tail 50
```

## References

- [Azure API Management VNet Integration](https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet)
- [Azure Container Apps Networking](https://learn.microsoft.com/en-us/azure/container-apps/networking)
- [Private DNS Zones](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)

## Conclusion

This implementation successfully achieves:
- ✅ APIM publicly accessible from the internet
- ✅ Container Apps private (not accessible from internet)
- ✅ APIM can reach Container Apps through VNet
- ✅ Secure communication using HTTPS
- ✅ Proper DNS resolution within VNet
- ✅ Infrastructure as Code using Terraform

The key insight is using APIM External mode with VNet injection combined with Container App Environment's internal load balancer to create a secure architecture where APIM acts as the public gateway to private backend services.
