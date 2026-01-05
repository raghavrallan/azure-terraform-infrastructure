output "name" {
  value = azurerm_container_app.container_app.name
}

output "host" {
  value = azurerm_container_app.container_app.ingress[0].fqdn
}