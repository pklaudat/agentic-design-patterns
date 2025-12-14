data "azurerm_client_config" "current" {}

locals {
  current_user_object_id = data.azurerm_client_config.current.object_id
  admin_object_id = compact([local.current_user_object_id, var.write_access_principal_id])
}

data "azurerm_cosmosdb_sql_role_definition" "data_contributor" {
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = "00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
}

resource "azurerm_cosmosdb_sql_role_assignment" "data_contributor" {
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.data_contributor.id
  principal_id        = local.current_user_object_id
  scope               = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_cosmosdb_account.this.resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${azurerm_cosmosdb_account.this.name}"
}
