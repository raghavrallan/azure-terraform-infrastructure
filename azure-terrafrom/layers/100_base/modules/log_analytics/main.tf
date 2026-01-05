resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "INFRA-law-analytics-${var.Env}-${var.rg_location}-${var.counts}"
  location            = var.rg_location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = var.data_retention
  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "log_analytics"

  }
}

