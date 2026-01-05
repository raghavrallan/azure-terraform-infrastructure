resource "azurerm_container_registry" "acr" {
  name                = "ztfacrregistory${var.Env}${var.rg_location}${var.counts}v2"
  resource_group_name = var.rg_name
  location            = var.rg_location
  sku                 = var.sku_name
  admin_enabled       = true

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "registory"
  }

}