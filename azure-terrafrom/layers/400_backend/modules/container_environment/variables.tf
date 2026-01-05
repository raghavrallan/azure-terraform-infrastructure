variable "rg_location" {
  type = string
}

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

variable "subnet_id" {
  type = string
}

variable "log_analytics_id" {
  type = string
}

variable "new_rg" {
  type = string
}

variable "workload_profile_type" {
  type = string
}

variable "internal_load_balancer_enabled" {
  type        = bool
  description = "Enable internal load balancer for private Container Apps"
  default     = false
}


