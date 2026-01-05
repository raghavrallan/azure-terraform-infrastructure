resource "azurerm_subnet" "subnet" {
  name                 = "ZTF-vnw-subnet-${var.Env}-${var.rg_location}-${var.subnet_name}"
  resource_group_name  = var.rg_name
  virtual_network_name = var.v_net_name
  address_prefixes     = [var.subnet_cidr]

  dynamic "delegation" {
    for_each = var.delegation == "container_app" ? [true] : []
    content {
      name = "container-apps"

      service_delegation {
        name = "Microsoft.App/environments"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action"
        ]
      }
    }
  }
}