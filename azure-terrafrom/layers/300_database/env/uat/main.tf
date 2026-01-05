# 300_database

module "cosmosdb_account" {
  source      = "../../modules/cosmosdb_account"
  Env         = var.Env
  rg_name     = var.rg_name
  rg_location = var.rg_location
  counts      = "001"
}

module "cosmos_database" {
  source              = "../../modules/cosmosdb"
  cosmos_account_name = module.cosmosdb_account.name
  database_name       = "INFRA-uat-db"
  throughput          = 400
  rg_name             = var.rg_name

  depends_on = [module.cosmosdb_account]
}

module "private_dns_zone" {
  source        = "../../../../modules/private_dns_zone/dns_zone"
  Env           = var.Env
  rg_name       = var.rg_name
  dns_zone_name = "privatelink.documents.azure.com"
}

module "vnet_link_to_dns_zone" {
  source        = "../../../../modules/private_dns_zone/vnet_link"
  Env           = var.Env
  rg_name       = var.rg_name
  dns_zone_name = module.private_dns_zone.name
  vnet_id       = data.terraform_remote_state.base.outputs.virtual_network_id

  depends_on = [module.private_dns_zone]
}

module "private_endpoint" {
  source                 = "../../../../modules/private_endpoint"
  Env                    = var.Env
  rg_name                = var.rg_name
  rg_location            = var.rg_location
  subnet_id              = data.terraform_remote_state.base.outputs.private_link_subnet_id
  pe_resource_id         = module.cosmosdb_account.id
  subresource_name       = ["sql"]
  link_name              = "uat-cosmosdb-pe"
  private_dns_zone_group = true
  DNS_id                 = module.private_dns_zone.id

  depends_on = [module.cosmos_database]
}

module "rbac_cosmos_assignment" {
  source              = "../../modules/rbac_assignment"
  rg_name             = var.rg_name
  cosmos_account_name = module.cosmosdb_account.name
  role_id             = "00000000-0000-0000-0000-000000000002"
  object_id           = data.terraform_remote_state.base.outputs.identity_object_id
  scope               = module.cosmosdb_account.id

  depends_on = [module.cosmos_database]
}

module "cosmos_monitoring" {
  source             = "../../../../modules/diagnostic"
  target_id          = module.cosmosdb_account.id
  storage_account_id = data.terraform_remote_state.storage.outputs.storage_account_id
  log_analytics_id   = data.terraform_remote_state.base.outputs.log_analytics_id
  Env                = var.Env
  location           = var.rg_location
  counts             = "001"
}