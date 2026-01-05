resource "azurerm_monitor_metric_alert" "alerts" {
  name                = "ZTF-alt-alerts-${var.Env}-global-${var.resource_name}-${var.counts}"
  resource_group_name = var.rg_name
  scopes              = [var.resource_id]
  description         = var.description
  severity            = var.severity
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = var.metric_namespace
    metric_name      = var.metric_name
    aggregation      = var.aggregation
    operator         = var.operator
    threshold        = var.threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = {
    Env         = var.Env
    EnvAcct     = local.EnvAcct
    AppSuite    = "alert"
    Application = "act"
  }
}