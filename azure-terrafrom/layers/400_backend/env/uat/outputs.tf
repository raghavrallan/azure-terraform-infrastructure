# 400_backend

output "acr_name" {
  value = module.container_registry_001.admin_username
}

output "acr_password" {
  value     = module.container_registry_001.admin_password
  sensitive = true
}

output "container_app_name" {
  value = module.container_app_001.name
}