resource "azurerm_cosmosdb_sql_database" "database" {
  name                = var.database_name
  resource_group_name = var.rg_name
  account_name        = var.cosmos_account_name
  throughput          = var.throughput
}