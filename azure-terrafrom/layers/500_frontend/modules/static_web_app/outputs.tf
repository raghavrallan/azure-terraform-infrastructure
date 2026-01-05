output "web_app_token" {
  value = azurerm_static_web_app.static_web_app.api_key
}

output "id" {
  value = azurerm_static_web_app.static_web_app.id
}

output "default_host_name" {
  value = azurerm_static_web_app.static_web_app.default_host_name
}

output "name" {
  value = azurerm_static_web_app.static_web_app.name
}