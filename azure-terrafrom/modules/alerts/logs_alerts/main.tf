resource "azurerm_monitor_scheduled_query_rules_alert" "storage_alert" {
  name                    = "ZTF-alt-alerts-${var.Env}-global-${var.counts}"
  location                = var.rg_location
  resource_group_name     = var.rg_name
  auto_mitigation_enabled = var.auto_resolve

  action {
    action_group = [var.action_group_id]
  }

  data_source_id = var.log_analytics_id
  description    = var.description
  enabled        = true
  query          = var.query
  severity       = var.severity
  frequency      = 5
  time_window    = 5

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "alert"
  }
}