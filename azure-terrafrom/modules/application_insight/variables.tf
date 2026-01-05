variable "counts" {
  type = string
}

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
    condition     = contains(["prod", "uat"], var.Env)
    error_message = "Please enter a valid value from dev qa demo2 prod"
  }
}

variable "workspace_id" {
  type = string
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}
