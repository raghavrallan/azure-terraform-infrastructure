resource "azurerm_container_app_environment" "app_enviornment" {
  name                               = "INFRA-cae-appenv-${var.Env}-${var.rg_location}-${var.counts}"
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

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "app_enviornment"
  }
}