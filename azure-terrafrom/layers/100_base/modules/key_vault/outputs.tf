output "id" {
  value = azurerm_key_vault.key_vault.id
}

output "name" {
  value = azurerm_key_vault.key_vault.name
}

output "identity_id" {
  value = azurerm_user_assigned_identity.identity.id
}

output "client_id" {
  value = azurerm_user_assigned_identity.identity.client_id
}

output "object_id" {
  value = azurerm_user_assigned_identity.identity.principal_id
}