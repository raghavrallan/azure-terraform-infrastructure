variable "Env" {
  type    = string
  default = "UAT"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "d4cec067-dee4-4a2f-8683-b2e476ed32b6"
}

variable "org_service_url" {
  type    = string
  default = "https://dev.azure.com/YourOrganization/"
}
