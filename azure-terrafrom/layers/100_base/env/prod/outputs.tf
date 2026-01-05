# 100_base

output "virtual_network_name" {
  value = module.virtual_network.name
}

output "virtual_network_id" {
  value = module.virtual_network.id
}

output "key_vault_name" {
  value = module.key_vault.name
}

output "private_link_subnet_id" {
  value = module.private_link_subnet.id
}

output "key_vault_id" {
  value = module.key_vault.id
}

output "container_app_subnet_id" {
  value = module.container_app_subnet.id
}

output "identity_id" {
  value = module.key_vault.identity_id
}

output "identity_client_id" {
  value = module.key_vault.client_id
}

output "identity_object_id" {
  value = module.key_vault.object_id
}

output "log_analytics_id" {
  value = module.log_analytics.id
}

output "application_insight_connection_string" {
  value     = module.application_insight.connection_string
  sensitive = true
}

output "application_insight_id" {
  value = module.application_insight.id
}

output "application_insight_instrumentation_key" {
  value     = module.application_insight.instrumentation_key
  sensitive = true
}

# Application Gateway Resources
output "app_gateway_subnet_id" {
  value       = module.app_gateway_subnet.id
  description = "Subnet ID for Application Gateway"
}

output "public_ip_id" {
  value       = module.public_ip_appgw.id
  description = "Public IP resource ID for Application Gateway"
}

output "public_ip_address" {
  value       = module.public_ip_appgw.ip_address
  description = "Public IP address value"
}

output "certificate_id" {
  value       = "https://${module.key_vault.name}.vault.azure.net/secrets/ssl-certificate"
  description = "SSL certificate secret ID in Key Vault"
}

output "apim_subnet_id" {
  value       = module.apim_subnet.id
  description = "Subnet ID for API Management VNet injection"
}