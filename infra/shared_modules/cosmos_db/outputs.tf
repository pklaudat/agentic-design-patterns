output "endpoint" {
  value = azurerm_cosmosdb_account.this.endpoint
}

output "database_id" {
  value = { for db in var.databases_config: db.name => azapi_resource.database[db.name].id}
}

output "database_name" {
  value = { for db in var.databases_config: db.name => azapi_resource.database[db.name].name}
}

output "name" {
  value = azurerm_cosmosdb_account.this.name
}

output "id" {
  value = azurerm_cosmosdb_account.this.id
}