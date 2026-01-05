output "instrumentation_key" {
  value     = azurerm_application_insights.insight.instrumentation_key
  sensitive = true
}

output "connection_string" {
  value     = azurerm_application_insights.insight.connection_string
  sensitive = true
}

output "id" {
  value = azurerm_application_insights.insight.id
}