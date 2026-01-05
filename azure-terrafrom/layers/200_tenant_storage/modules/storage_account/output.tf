output "name" {
  value = azurerm_storage_account.storage.name
}

output "id" {
  value = azurerm_storage_account.storage.id
}

output "endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "static_website_url" {

  value = var.static_website ? azurerm_storage_account.storage.primary_web_endpoint : null
}
