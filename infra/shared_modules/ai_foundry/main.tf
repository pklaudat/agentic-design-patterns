data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}



resource "azapi_resource" "ai_foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-07-01-preview"
  name      = "${var.project_name}-foundry"
  location  = var.location
  parent_id = data.azurerm_resource_group.this.id

  properties = {
    publicNetworkAccess           = "Enabled"
    local_authentication_disabled = true


    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }
  }

  depends_on = [azurerm_resource_group.this]
}