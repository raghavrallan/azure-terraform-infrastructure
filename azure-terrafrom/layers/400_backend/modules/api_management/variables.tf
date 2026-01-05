variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["dev", "prod", "qa", "demo", "research"], var.Env)
    error_message = "Please enter a valid value from dev qa demo2 prod"
  }
}

variable "rg_name" {
  type = string
}

variable "rg_location" {
  type = string
}

variable "counts" {
  type = string
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "publisher_email" {
  type = string
}

variable "publisher_name" {
  type = string
}
variable "sku_name" {
  type = string
}

variable "application_insights_key" {
  type = string
}

variable "application_insights_id" {
  type = string
}

variable "identity_id" {
  type = list(string)
}

variable "backend_url" {
  type        = string
  description = "The URL of the backend Container App"
  default     = null
}

variable "virtual_network_type" {
  type        = string
  description = "The type of virtual network configuration (None, External, Internal)"
  default     = "None"
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID for VNet injection"
  default     = null
}