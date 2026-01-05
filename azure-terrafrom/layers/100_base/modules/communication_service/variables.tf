locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "Env" {
  type        = string
  description = "Enter the specified Environment"
  validation {
    condition     = contains(["staging", "prod", "uat", ], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}


variable "rg_name" {
  type = string
}

variable "counts" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "rg_location" {
  type = string
}