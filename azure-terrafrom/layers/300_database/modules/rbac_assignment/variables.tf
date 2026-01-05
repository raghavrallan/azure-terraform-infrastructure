variable "role_id" {
  description = "The role definition ID to assign."
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group."
  type        = string
}

variable "cosmos_account_name" {
  description = "The name of the Cosmos DB account."
  type        = string
}

variable "object_id" {
  description = "The object ID of the principal to assign the role to."
  type        = string
}

variable "scope" {
  description = "The scope at which the role assignment applies."
  type        = string
}