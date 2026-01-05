resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "ztf-cns-account-${var.Env}-${var.rg_location}-${var.counts}-v2"
  location            = var.rg_location
  resource_group_name = var.rg_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  free_tier_enabled   = var.free_tier

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  capacity {
    total_throughput_limit = 1000
  }

  geo_location {
    location          = var.rg_location
    failover_priority = 0
  }

  public_network_access_enabled = false

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "cosmosdb"
  }
}
