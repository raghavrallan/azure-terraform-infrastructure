output "name" {
  value = azurerm_api_management.api_management.name
}
output "id" {
  value = azurerm_api_management.api_management.id
}

output "default_dns" {
  value = azurerm_api_management.api_management.gateway_url
}