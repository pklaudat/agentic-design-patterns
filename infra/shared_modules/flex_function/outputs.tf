output "id" {
  value = azurerm_function_app_flex_consumption.this.id
}

output "principal_id" {
  value = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}