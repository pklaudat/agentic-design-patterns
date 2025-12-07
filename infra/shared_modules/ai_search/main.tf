

resource "azurerm_search_service" "this" {
  name                = var.search_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  identity {
    type         = "SystemAssigned"
    identity_ids = []
  }
  sku                           = "basic"
  replica_count                 = 1
  partition_count               = 1
  local_authentication_enabled  = false
  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = true
  semantic_search_sku           = "basic"
}
