resource "azurerm_key_vault_access_policy" "access" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = var.secret_permissions

  key_permissions = var.key_permissions

  storage_permissions = var.storage_permissions

}