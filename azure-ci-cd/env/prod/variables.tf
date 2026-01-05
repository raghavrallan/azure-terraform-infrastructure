# 200_datalake

variable "Env" {
  description = "The name of the environment, e.g. prod, uat, dev"
  type        = string
  default     = "prod"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

variable "org_service_url" {
  type    = string
  default = "https://dev.azure.com/XXXXXXXXXXX/"
}