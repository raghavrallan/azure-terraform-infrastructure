resource "azurerm_api_management" "api_management" {
  name                 = "INFRA-api-apimanagement-${var.Env}-eastus-${var.counts}-v2"
  location             = var.rg_location
  resource_group_name  = var.rg_name
  publisher_name       = var.publisher_name
  publisher_email      = var.publisher_email
  sku_name             = var.sku_name
  virtual_network_type = var.virtual_network_type

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != "None" && var.subnet_id != null ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = var.identity_id
  }
  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "api_management"
  }
}

resource "azurerm_api_management_logger" "logger" {
  name                = "INFRA-api-apilogger-${var.Env}-eastus-${var.counts}"
  api_management_name = azurerm_api_management.api_management.name
  resource_group_name = var.rg_name
  resource_id         = var.application_insights_id

  application_insights {
    instrumentation_key = var.application_insights_key
  }
}

# Backend configuration for Container App
resource "azurerm_api_management_backend" "container_app_backend" {
  name                = "container-app-backend"
  resource_group_name = var.rg_name
  api_management_name = azurerm_api_management.api_management.name
  protocol            = "http"
  url                 = "https://${var.backend_url}"
  description         = "Backend for Container App"
}

# API definition
resource "azurerm_api_management_api" "main_api" {
  name                = "container-app-api"
  resource_group_name = var.rg_name
  api_management_name = azurerm_api_management.api_management.name
  revision            = "1"
  display_name        = "Container App API"
  path                = "api"
  protocols           = ["https"]
  service_url         = "https://${var.backend_url}"

  subscription_required = false
}

# Wildcard operation to proxy all requests
resource "azurerm_api_management_api_operation" "proxy_all" {
  operation_id        = "proxy-all"
  api_name            = azurerm_api_management_api.main_api.name
  api_management_name = azurerm_api_management.api_management.name
  resource_group_name = var.rg_name
  display_name        = "Proxy all operations"
  method              = "GET"
  url_template        = "/*"
  description         = "Proxy all GET requests to the backend Container App"
}

# API operation policy to use the backend
resource "azurerm_api_management_api_operation_policy" "proxy_policy" {
  api_name            = azurerm_api_management_api.main_api.name
  api_management_name = azurerm_api_management.api_management.name
  resource_group_name = var.rg_name
  operation_id        = azurerm_api_management_api_operation.proxy_all.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service base-url="https://${var.backend_url}" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}