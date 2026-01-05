# 400_backend

module "container_registry_001" {
  source      = "../../modules/container_registry"
  Env         = var.Env
  counts      = "001"
  rg_name     = var.rg_name
  rg_location = var.rg_location
  sku_name    = "Basic"
}

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
  internal_load_balancer_enabled = true # Enable internal load balancer - Container Apps only accessible within VNet
}

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
  external_enabled   = true # Enable ingress - with internal environment, still only accessible within VNet

  container_secrets = [
    {
      name  = "acr-password"
      value = module.container_registry_001.admin_password
    }
  ]

  environment_variable = []
}

# Firewall Policy for Application Gateway (Only for WAF_v2 SKU)
# Comment out for Standard_v2 as it doesn't support firewall policies
# module "firewall_policy_001" {
#   source      = "../../modules/firewall_poilcy"
#   Env         = var.Env
#   counts      = "001"
#   rg_name     = var.rg_name
#   rg_location = var.rg_location
#   location    = var.rg_location
# }

# Application Gateway for Container App
module "application_gateway_001" {
  source             = "../../modules/application_gateway"
  Env                = var.Env
  counts             = "001"
  rg_name            = var.rg_name
  rg_location        = var.rg_location
  subnet_id          = data.terraform_remote_state.base.outputs.app_gateway_subnet_id
  public_ip          = data.terraform_remote_state.base.outputs.public_ip_id
  targaet_list       = [module.container_app_001.host]
  certificate_id     = data.terraform_remote_state.base.outputs.certificate_id
  identity_id        = data.terraform_remote_state.base.outputs.identity_id
  firewall_policy_id = null          # null for Standard_v2, use module.firewall_policy_001.id for WAF_v2
  sku                = "Standard_v2" # Developer tier - use Standard_v2 with capacity 1
  capacity           = 1             # Single instance for developer tier
  location           = var.rg_location
}

module "api_management" {
  source                   = "../../modules/api_management"
  Env                      = var.Env
  rg_name                  = var.rg_name
  rg_location              = var.rg_location
  publisher_name           = "Tech Support"
  publisher_email          = "tech@ztaegis.com"
  sku_name                 = "Developer_1" # Developer plan with VNet injection support
  application_insights_id  = data.terraform_remote_state.base.outputs.application_insight_id
  application_insights_key = data.terraform_remote_state.base.outputs.application_insight_instrumentation_key
  identity_id              = [data.terraform_remote_state.base.outputs.identity_id]
  counts                   = "001"
  backend_url              = "ztf-cap-container-prod-eus-001.yellowmeadow-9ccbae2e.eastus.azurecontainerapps.io" # Connect to Container App via internal FQDN
  virtual_network_type     = "External"                                                                          # External mode - APIM publicly accessible but can reach private Container Apps
  subnet_id                = data.terraform_remote_state.base.outputs.apim_subnet_id
}