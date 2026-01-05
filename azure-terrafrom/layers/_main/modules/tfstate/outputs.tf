# tfstate module

output "resource_group_name" {
  description = "Resource group for terraform state managment"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage account for terraform state managment"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_account_location" {
  description = "Storage account location for terraform state managment"
  value       = azurerm_storage_account.tfstate.location
}

output "container_name" {
  description = "Storage account for terraform state managment"
  value       = azurerm_storage_container.tfstate.name
}
