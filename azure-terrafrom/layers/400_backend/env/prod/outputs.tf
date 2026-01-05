# 400_backend

output "acr_name" {
  value = module.container_registry_001.admin_username
}

output "acr_password" {
  value     = module.container_registry_001.admin_password
  sensitive = true
}

output "acr_login_server" {
  value = module.container_registry_001.login_server
}

output "container_app_name" {
  value = module.container_app_001.name
}

output "container_app_fqdn" {
  value       = module.container_app_001.host
  description = "Internal FQDN of the Container App (only accessible via Application Gateway)"
}

output "application_gateway_public_ip" {
  value       = data.terraform_remote_state.base.outputs.public_ip_address
  description = "Public IP address of the Application Gateway"
}

output "api_management_name" {
  value       = module.api_management.name
  description = "Name of the API Management instance"
}

output "api_management_gateway_url" {
  value       = module.api_management.default_dns
  description = "Gateway URL of the API Management instance"
}