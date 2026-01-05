variable "dns_zone_name" {
  description = "The name of the private DNS zone"
  type        = string
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat"], var.Env)
    error_message = "Please enter a valid value from dev uat prod"
  }
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_id" {
  description = "The ID of the virtual network to link to the private DNS zone"
  type        = string
}