# 100_base

module "key_vault" {
  source      = "../../modules/key_vault"
  rg_location = var.rg_location
  rg_name     = var.rg_name
  Env         = var.Env
  tenant_id   = data.azurerm_client_config.current.tenant_id
  object_id   = data.azurerm_client_config.current.object_id
}

module "virtual_network" {
  source      = "../../modules/v_net"
  cidr_v_net  = "10.0.0.0/16"
  Env         = var.Env
  rg_name     = var.rg_name
  rg_location = var.rg_location
  counts      = "001"
}

module "private_link_subnet" {
  source      = "../../modules/subnet"
  Env         = var.Env
  subnet_name = "privatelink"
  subnet_cidr = "10.0.3.0/24"
  rg_location = var.rg_location
  v_net_name  = module.virtual_network.name
  rg_name     = var.rg_name
  delegation  = false

  depends_on = [module.virtual_network]
}

module "container_app_subnet" {
  source      = "../../modules/subnet"
  Env         = var.Env
  subnet_name = "container-app"
  subnet_cidr = "10.0.2.0/24"
  rg_location = var.rg_location
  v_net_name  = module.virtual_network.name
  rg_name     = var.rg_name
  delegation  = "container_app"

  depends_on = [module.virtual_network]
}

module "log_analytics" {
  source         = "../../modules/log_analytics"
  Env            = var.Env
  rg_name        = var.rg_name
  rg_location    = var.rg_location
  counts         = "001"
  data_retention = 30
}

module "communication_serivce" {
  source       = "../../modules/communication_service"
  Env          = var.Env
  rg_name      = var.rg_name
  rg_location  = var.rg_location
  counts       = "001"
  key_vault_id = module.key_vault.id
}

module "application_insight" {
  source       = "../../../../modules/application_insight"
  rg_location  = var.rg_location
  rg_name      = var.rg_name
  Env          = var.Env
  counts       = "001"
  workspace_id = module.log_analytics.id
}

module "rbac_policy_for_storage" {
  source      = "../../../../modules/access_control/role_assignment"
  resource_id = module.communication_serivce.id
  permission  = module.communication_role.name
  object_id   = module.key_vault.object_id

  depends_on = [module.communication_role]
}

##################################################### ROLES ###############################################

module "communication_role" {
  source           = "../../modules/roles"
  role_description = "Role to allow access to Communication Service"
  role_name        = "CommunicationServiceAccessRole"
  allowed_actions = [
    "Microsoft.Communication/EmailServices/read",
    "Microsoft.Communication/EmailServices/write",
    "Microsoft.Communication/EmailServices/Domains/read",
    "Microsoft.Communication/CommunicationServices/read",
    "Microsoft.Communication/CommunicationServices/write",
    "Microsoft.Communication/Locations/OperationStatuses/read",
    "Microsoft.Communication/Locations/OperationStatuses/write",
    "Microsoft.Communication/EmailServices/Domains/SenderUsernames/read"
  ]
  subscription_id = var.subscription_id
  Env             = var.Env
}

module "communication_monitoring" {
  source           = "../../../../modules/diagnostic"
  target_id        = module.communication_serivce.id
  log_analytics_id = module.log_analytics.id
  Env              = var.Env
  location         = var.rg_location
  counts           = "001"
}

module "key_monitoring" {
  source           = "../../../../modules/diagnostic"
  target_id        = module.key_vault.id
  log_analytics_id = module.log_analytics.id
  Env              = var.Env
  location         = var.rg_location
  counts           = "001"
}