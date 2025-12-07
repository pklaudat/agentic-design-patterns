

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


# module "flex_function" {
#   source               = "./shared_modules/flex_function"
#   function_app_name    = "${var.project_name}-fnapp"
#   storage_account_name = "${replace(var.project_name, "-", "")}stg"
#   resource_group_name  = azurerm_resource_group.this.name
#   location             = var.location
#   depends_on           = [azurerm_resource_group.this]
# }


module "vector_database" {
  source              = "./shared_modules/cosmos_db"
  cosmos_db_account_name = "${var.project_name}-cosmosdb"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  free_tier_enabled = true
  databases_config = [{
    name = "vectorSearchDB"
    throughput = 400
    containers = [{
      name            = "vectors"
      partition_key   = "/id"
      throughput      = 400
      vector_embedding_policy = [{
        path             = "/vector"
        distanceFunction = "cosine"
        dimensions      = 1536
        dataType = "float32"
      }]
      indexing_policy = {
        includedPaths = [{
          path       = "/*"
        }]
        excludedPaths = [{
          path       = "/\"_etag\"/?"
        }]
        vectorIndexes = [{
          path       = "/vector"
          type       = "quantizedFlat"
        }]
      }
    }]
  }]
  ip_range_filter = [trim(data.http.my_ip.response_body, " ")]

  depends_on = [azurerm_resource_group.this]
}
