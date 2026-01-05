# 200_tenant_storage

output "storage_account_name" {
  value = module.storage.name
}

output "storage_account_id" {
  value = module.storage.id
}

output "storage_account_endpoint" {
  value = module.storage.endpoint
}