
output "search_service_id" {
  description = "The ID of the Azure Search Service."
  value       = azurerm_search_service.this.id
}

output "search_service_endpoint" {
  description = "The endpoint URL of the Azure Search Service."
  value       = azurerm_search_service.this.endpoint
}

output "principal_id" {
  description = "The object id of the system assigned managed identity."
  value       = azurerm_search_service.this.identity[0].principal_id
}