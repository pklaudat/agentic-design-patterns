

locals {
  capabilities = ["EnableNoSQLVectorSearch"]
}


resource "azurerm_cosmosdb_account" "this" {
  name                = var.cosmos_db_account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  identity {
    type = "SystemAssigned"
  }

  free_tier_enabled = var.free_tier_enabled

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # default_identity_type = "SystemAssignedIdentity"

  network_acl_bypass_for_azure_services = false
  is_virtual_network_filter_enabled     = true
  public_network_access_enabled         = true

  backup {
    type                = "Periodic"
    storage_redundancy  = "Local"
    retention_in_hours  = 8
    interval_in_minutes = 1440
  }



  ip_range_filter = var.ip_range_filter

  minimal_tls_version = "Tls12"

  local_authentication_disabled = true

  dynamic "capabilities" {
    for_each = local.capabilities
    content {
      name = capabilities.value
    }
  }
}