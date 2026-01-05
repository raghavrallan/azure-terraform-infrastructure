# 600_backend

variable "Env" {
  description = "The name of the environment, e.g. prod, uat, dev"
  type        = string
  default     = "uat"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "d4cec067-dee4-4a2f-8683-b2e476ed32b6"
}

variable "rg_name" {
  description = "The name of the resource group"
  type        = string
  default     = "INFRA-UAT-BACKEND"
}

variable "rg_location" {
  description = "The Azure region the resource group should reside in"
  type        = string
  default     = "eastus"
}