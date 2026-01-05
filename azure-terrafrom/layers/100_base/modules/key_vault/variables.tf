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
    condition     = contains(["prod", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "tenant_id" {
  type = string
}

variable "object_id" {
  type = string
}