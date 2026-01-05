variable "rg_name" {
  type = string
}

variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["staging", "prod", "uat", ], var.Env)
    error_message = "Please enter a valid value from dev staging uat uat prod"
  }
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "counts" {
  type = string
}

variable "container_cpu" {
  type = string
}

variable "container_memory" {
  type = string
}

variable "app_environment_id" {
  type = string
}

variable "image" {
  type = string
}

variable "acr_password" {
  type = string
}

variable "acr_server" {
  type = string
}

variable "acr_username" {
  type = string
}

variable "environment_variable" {
  type = list(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
}

variable "min_replicas" {
  type = number
}

variable "max_replicas" {
  type = number
}

variable "container_port" {
  type = number
}

variable "location" {
  type = string
}

locals {
  first_char     = substr(var.location, 0, 1)
  last_two_chars = substr(var.location, length(var.location) - 2, 2)
  location       = "${local.first_char}${local.last_two_chars}"
}

variable "identity_ids" {
  type = list(string)
}

variable "container_secrets" {
  description = "Dynamic secrets for the Container App"
  type = list(object({
    name                = string
    identity            = optional(string)
    value               = optional(string)
    key_vault_secret_id = optional(string)
  }))
}

variable "external_enabled" {
  type        = bool
  default     = true
  description = "Enable external access to the container app. Set to false for private endpoint only access."
}