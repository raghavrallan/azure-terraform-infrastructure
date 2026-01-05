resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name                       = "ZTF-mds-diagnostic-${var.Env}-${local.location}-${var.counts}"
  target_resource_id         = var.target_id
  storage_account_id         = var.storage_account_id
  log_analytics_workspace_id = var.log_analytics_id

  dynamic "enabled_log" {
    for_each = length(data.azurerm_monitor_diagnostic_categories.diagnostic_categories.log_category_groups) > 0 ? data.azurerm_monitor_diagnostic_categories.diagnostic_categories.log_category_groups : []
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.diagnostic_categories.metrics
    content {
      category = metric.value
    }
  }
}

