resource "azuredevops_serviceendpoint_azurerm" "service_endpoint" {
  project_id                = var.project_id
  service_endpoint_name     = var.service_endpoint_name
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = var.subscription_name

  # Optional description or tag
  description = "Azure Service Connection for ${var.service_endpoint_name}"
}
