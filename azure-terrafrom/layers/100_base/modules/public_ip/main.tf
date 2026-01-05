resource "azurerm_public_ip" "public_ip" {
  name                = "ZTF-pip-${var.Env}-${var.rg_location}-${var.counts}"
  location            = var.rg_location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "public_ip"
  }
}
