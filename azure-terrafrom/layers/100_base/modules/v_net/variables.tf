variable "rg_location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "cidr_v_net" {
  type = string
}

variable "counts" {
  type = string
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "Env" {
  type        = string
  description = "Enter the specified Environment"
  validation {
    condition     = contains(["prod", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}
