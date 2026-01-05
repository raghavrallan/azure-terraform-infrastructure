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

variable "rg_location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "counts" {
  type = string
}

variable "data_retention" {
  type = number
}