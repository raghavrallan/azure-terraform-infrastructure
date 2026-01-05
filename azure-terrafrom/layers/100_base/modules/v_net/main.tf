resource "azurerm_virtual_network" "virtual_network" {
  name                = "INFRA-vnw-network-${var.Env}-${var.rg_location}-${var.counts}"
  location            = var.rg_location
  resource_group_name = var.rg_name
  address_space       = [var.cidr_v_net]

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSutie = "v_net"
  }
}