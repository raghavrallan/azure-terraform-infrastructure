resource "azurerm_static_web_app" "static_web_app" {
  name                = "ZTF-swa-webapp-${var.Env}-centralus-${var.counts}"
  resource_group_name = var.rg_name
  location            = "centralus"
  sku_tier            = var.sku
  sku_size            = var.sku

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "frontend"
  }
}