data "azurerm_monitor_diagnostic_categories" "diagnostic_categories" {
  resource_id = var.target_id
}
