variable "Env" {
  description = "The name of the environment, e.g. prod, qa, dev"
  type        = string
  default     = "prod"
}

variable "subscription_id" {
  description = "The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx subcription id"
  type        = string
  default     = "5d5e0746-817a-49c6-b53d-bc26d8bc1850"
}

variable "rg_location" {
  default = "centralus"
}

variable "rg_name" {
  default = "ZTF-PROD-FRONTEND"
}