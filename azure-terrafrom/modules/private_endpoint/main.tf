resource "azurerm_private_endpoint" "ep" {
  name                = "ztf-${var.link_name}-endpoint"
  location            = var.rg_location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = var.link_name
    private_connection_resource_id = var.pe_resource_id
    is_manual_connection           = false
    subresource_names              = var.subresource_name
  }
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_group ? [1] : []

    content {
      name                 = var.link_name
      private_dns_zone_ids = [var.DNS_id]
    }
  }

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "endpoint"
  }
}