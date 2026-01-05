# _main

output "resource_group_name" {
  description = "Resource group for terraform state managment"
  value       = module.tfstate.resource_group_name
}

output "storage_account_name" {
  description = "Storage account for terraform state managment"
  value       = module.tfstate.storage_account_name
}

output "storage_account_location" {
  description = "Storage account location for terraform state managment"
  value       = module.tfstate.storage_account_location
}

output "container_name" {
  description = "Storage account for terraform state managment"
  value       = module.tfstate.container_name
}