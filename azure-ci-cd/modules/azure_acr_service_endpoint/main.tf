resource "azuredevops_serviceendpoint_azurecr" "acr_endpoint" {
  project_id                = var.project_id
  service_endpoint_name     = var.service_endpoint_name
  resource_group            = var.resource_group
  azurecr_spn_tenantid      = var.tenant_id
  azurecr_name              = var.acr_name
  azurecr_subscription_id   = var.subscription_id
  azurecr_subscription_name = var.subscription_name
}
