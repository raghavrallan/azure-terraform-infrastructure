# 300_database

resource "azurerm_cosmosdb_sql_role_assignment" "rbac_assignment" {
  resource_group_name = var.rg_name
  account_name        = var.cosmos_account_name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.role_definition.id
  principal_id        = var.object_id
  scope               = var.scope
}