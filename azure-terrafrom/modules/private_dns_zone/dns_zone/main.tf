# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = var.rg_name

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "private_dns_zone"
  }
}