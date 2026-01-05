resource "azurerm_private_dns_zone_virtual_network_link" "v_net_link" {
  name                  = "${var.Env}-vnet-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = var.dns_zone_name
  virtual_network_id    = var.vnet_id

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "v_net_link"
  }
}