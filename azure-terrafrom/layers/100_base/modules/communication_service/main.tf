resource "azurerm_communication_service" "communication_service" {
  name                = "INFRA-cms-communication-${var.Env}-${var.rg_location}-${var.counts}-v2"
  resource_group_name = var.rg_name
  data_location       = "United States"

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "communication"
  }
}

resource "azurerm_email_communication_service" "email_service" {
  name                = "INFRA-ecm-email-${var.Env}-${var.rg_location}-${var.counts}"
  resource_group_name = var.rg_name
  data_location       = "United States"

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "email"
  }
}

resource "azurerm_key_vault_secret" "acs-connection-string" {
  name         = "azure-${var.Env}-acs-connection-string"
  value        = azurerm_communication_service.communication_service.primary_connection_string
  key_vault_id = var.key_vault_id
}