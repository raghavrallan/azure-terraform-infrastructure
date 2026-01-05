resource "azurerm_storage_account" "storage" {
  name                          = "ztf${var.Env}storage${var.counts}v2"
  resource_group_name           = var.rg_name
  location                      = var.rg_location
  account_tier                  = "Standard"
  account_replication_type      = "RAGZRS"
  public_network_access_enabled = true
  https_traffic_only_enabled    = true
  is_hns_enabled                = true

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }

  blob_properties {

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  dynamic "static_website" {
    for_each = var.static_website ? [1] : []
    content {
      index_document     = "index.html"
      error_404_document = "error.html"
    }
  }

  tags = {
    Env      = var.Env
    EnvAcct  = local.EnvAcct
    AppSuite = "storage"
  }
}