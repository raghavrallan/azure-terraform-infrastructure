variable "rg_location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "link_name" {
  type = string
}

variable "pe_resource_id" {
  type = string
}

variable "subresource_name" {
  type = list(string)
}

variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}

variable "DNS_id" {
  type    = string
  default = null
}

variable "private_dns_zone_group" {
  type = bool
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}