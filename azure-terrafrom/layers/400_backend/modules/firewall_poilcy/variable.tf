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
    condition     = contains(["prod"], var.Env)
    error_message = "Please enter a valid value from dev uat demo2 prod"
  }
}

locals {
  EnvAcct        = var.Env == "prod" ? "prod" : "nonp"
  first_char     = substr(var.location, 0, 1)
  last_two_chars = substr(var.location, length(var.location) - 2, 2)
  location       = "${local.first_char}${local.last_two_chars}"
}

variable "location" {
  type = string
}