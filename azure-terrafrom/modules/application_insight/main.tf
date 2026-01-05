resource "azurerm_application_insights" "insight" {
  name                = "INFRA-ain-insight-${var.Env}-eastus-${var.counts}"
  location            = var.rg_location
  resource_group_name = var.rg_name
  workspace_id        = var.workspace_id
  application_type    = "other"

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSutie = "insight"
  }
}