variable "rg_name" {
  description = "Name of the resource group"
  type        = string
}

variable "rg_location" {
  description = "Azure region"
  type        = string
}

variable "Env" {
  type        = string
  description = "Enter the specifyed Environment"
  validation {
    condition     = contains(["prod", "uat"], var.Env)
    error_message = "Please enter a valid value from dev uat uat prod"
  }
}

variable "counts" {
  type = string
}

variable "free_tier" {
  description = "Enable free tier for Cosmos DB account"
  type        = bool
  default     = true
}

locals {
  EnvAcct = var.Env == "prod" ? "prod" : "nonp"
}