output "id" {
  description = "Cosmos DB account ID"
  value       = azurerm_cosmosdb_account.cosmosdb.id
}

output "name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.cosmosdb.name
}

output "endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.cosmosdb.endpoint
}