# 100_base

variable "Env" {
  description = "The name of the environment, e.g. prod, uat, dev"
  type        = string
  default     = "prod"
}

variable "rg_location" {
  default = "eastus"
}
variable "rg_name" {
  description = "The name of the resource group"
  type        = string
  default     = "INFRA-PROD-MISC"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "5d5e0746-817a-49c6-b53d-bc26d8bc1850"
}