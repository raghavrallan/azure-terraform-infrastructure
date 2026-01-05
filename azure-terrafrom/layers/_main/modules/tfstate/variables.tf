# tfstate module

variable "env" {
  description = "The name of the environment, e.g. prod, uat, dev"
  type        = string
}

variable "region" {
  description = "The Azure region the state should reside in"
  type        = string
}


locals {
  EnvAcct = var.env == "prod" ? "prod" : "nonp"
}