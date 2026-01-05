# _main

variable "env" {
  description = "The name of the environment, e.g. prod, uat, dev"
  type        = string
  default     = "uat"
}

variable "region" {
  description = "The Azure region the state should reside in"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "d4cec067-dee4-4a2f-8683-b2e476ed32b6"
}