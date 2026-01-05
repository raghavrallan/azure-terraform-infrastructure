# 200_tenant_storage
# 200_tenant_storage

module "storage" {
  source       = "../../modules/storage_account"
  Env          = var.Env
  rg_name      = var.rg_name
  rg_location  = var.rg_location
  counts       = "001"
  key_vault_id = data.terraform_remote_state.base.outputs.key_vault_id
}

module "appdata_container" {
  source         = "../../modules/container"
  container_name = "appdata"
  storage_id     = module.storage.id

  depends_on = [module.storage]
}

module "private_dns_zone" {
  source        = "../../../../modules/private_dns_zone/dns_zone"
  Env           = var.Env
  rg_name       = var.rg_name
  dns_zone_name = "privatelink.blob.core.windows.net"
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
  pe_resource_id         = module.storage.id
  subresource_name       = ["Blob"]
  link_name              = "uat-cosmosdb-pe"
  private_dns_zone_group = true
  DNS_id                 = module.private_dns_zone.id

  depends_on = [module.storage]
}

module "rbac_policy_for_storage" {
  source      = "../../../../modules/access_control/role_assignment"
  resource_id = module.appdata_container.id
  permission  = "Storage Blob Data Contributor"
  object_id   = data.terraform_remote_state.base.outputs.identity_object_id

  depends_on = [module.appdata_container]
}

module "storage_account_monitoring" {
  source           = "../../../../modules/diagnostic"
  target_id        = module.storage.id
  log_analytics_id = data.terraform_remote_state.base.outputs.log_analytics_id
  Env              = var.Env
  location         = var.rg_location
  counts           = "001"
}