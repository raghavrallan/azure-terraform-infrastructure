variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["dev", "prod", "qa", "uat", "staging"], var.Env)
    error_message = "Please enter a valid value from dev qa uat prod"
  }
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}

variable "rg_name" {
  type = string
}

variable "counts" {
  type = string
}

variable "sku" {
  type = string
}