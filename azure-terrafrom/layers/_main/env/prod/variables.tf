# _main

variable "env" {
  description = "The name of the environment, e.g. prod, uat, dev"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "The Azure region the state should reside in"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "5d5e0746-817a-49c6-b53d-bc26d8bc1850"
}