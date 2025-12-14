

locals {
  resource_group_name = replace(replace(upper("${var.project_name}-${var.location}_RG"), "-", "_"), " ", "")
}

data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
}


# module "network" {
#   # note: this module has a subnet for a poc using azure container apps for github runners
#   # therefore it includes a subnet delegated to Microsoft.App/environment which is required
#   # for flexible consumption azure functions.
#   source        = "github.com/pklaudat/github-actions-azure-runners/modules/network?ref=main"
#   location      = var.location
#   address_space = var.virtual_network_address_space
#   depends_on = [ azurerm_resource_group.this ]
# }


module "flex_function" {
  source               = "./shared_modules/flex_function"
  function_app_name    = "${var.project_name}-v2-fnapp"
  storage_account_name = "${replace(var.project_name, "-", "")}stg"
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  app_settings = {
    COSMOSDB_URL = module.vector_database.endpoint
  }

  monitoring_enabled = true

  depends_on = [azurerm_resource_group.this]
}

module "vector_database" {
  source                       = "./shared_modules/cosmos_db"
  cosmos_db_account_name       = "${var.project_name}-cosmosdb"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  free_tier_enabled            = true
  readonly_access_principal_id = null
  databases_config = var.databases
  ip_range_filter = [trim(data.http.my_ip.response_body, " ")]

  depends_on = [azurerm_resource_group.this]

}

data "azurerm_cosmosdb_sql_role_definition" "data_reader" {
  resource_group_name = azurerm_resource_group.this.name
  account_name        = module.vector_database.name
  role_definition_id  = "00000000-0000-0000-0000-000000000001"
}


resource "azurerm_cosmosdb_sql_role_assignment" "data_reader" {
  resource_group_name = azurerm_resource_group.this.name
  account_name        = module.vector_database.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.data_reader.id
  principal_id        = module.flex_function.principal_id
  scope               = module.vector_database.id
}