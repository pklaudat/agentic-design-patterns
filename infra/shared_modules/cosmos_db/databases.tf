locals {
    containers = merge([
        for db in var.databases_config : {
            for container in db.containers : "${db.name}-${container.name}" => {
                database_name            = db.name
                container                = container
                partition_key            = container.partition_key
                vector_embedding_policy  = lookup(container, "vector_embedding_policy", [])
                indexing_policy          = container.indexing_policy
            }
        }
    ]...)
}

resource "azapi_resource" "database" {
  for_each = { for db in var.databases_config : db.name => db }

  type      = "Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-11-01-preview"
  name      = each.value.name
  parent_id = azurerm_cosmosdb_account.this.id
  location = azurerm_cosmosdb_account.this.location

  body = {
    properties = {
        resource = {
            createMode = "Default"
            id = each.value.name
        }
        options = {
            throughput = each.value.throughput
        }
        
    }
  }
}


resource "azapi_resource" "container" {
  for_each = local.containers

  type      = "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-11-01-preview"
  name      = each.value.container.name
  parent_id = azapi_resource.database[each.value.database_name].id

  body = {
    properties = {
        resource = {
            id             = each.value.container.name
            partitionKey   = {
                paths    = [each.value.container.partition_key]
                kind     = "Hash"
            }
            indexingPolicy = each.value.container.indexing_policy
            vectorEmbeddingPolicy = {vectorEmbeddings = each.value.container.vector_embedding_policy}
        }
        options = {
            throughput = each.value.container.throughput
        }   
    }
  }
}