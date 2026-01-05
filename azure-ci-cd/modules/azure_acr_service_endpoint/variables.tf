variable "project_id" {
  description = "Azure DevOps project ID"
  type        = string
}

variable "service_endpoint_name" {
  description = "Name of the Azure Container Registry service endpoint"
  type        = string
  default     = "Container Registry Endpoint"
}

variable "resource_group" {
  description = "Azure Resource Group containing the ACR"
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "subscription_name" {
  description = "Azure subscription name"
  type        = string
}
