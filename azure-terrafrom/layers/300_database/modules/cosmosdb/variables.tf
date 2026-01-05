variable "cosmos_account_name" {
  description = "The name of the Cosmos DB account"
  type        = string
}

variable "database_name" {
  description = "The name of the Cosmos DB SQL database"
  type        = string
}

variable "throughput" {
  description = "The throughput of the Cosmos DB SQL database"
  type        = number
  default     = 400
}

variable "rg_name" {
  description = "The name of the resource group"
  type        = string
}