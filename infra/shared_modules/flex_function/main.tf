locals {
  ip_restrictions = []
  base_app_settings = {
    "AzureWebJobsStorage__accountName"     = azurerm_storage_account.this.name
    "AzureWebJobsStorage__clientId"        = azurerm_user_assigned_identity.this.client_id
    "AzureWebJobsStorage__blobServiceUri"  = trimsuffix(azurerm_storage_account.this.primary_blob_endpoint, "/")
    "AzureWebJobsStorage__queueServiceUri" = trimsuffix(azurerm_storage_account.this.primary_queue_endpoint, "/")
    "AzureWebJobsStorage__tableServiceUri" = trimsuffix(azurerm_storage_account.this.primary_table_endpoint, "/")
    "AzureWebJobsStorage__credential"      = "managedidentity"
  }
  monitoring_app_settings = var.monitoring_enabled ? {
    "APPLICATIONINSIGHTS_AUTHENTICATION_STRING" = "Authorization=AAD"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"     = module.monitor.instrumentation_key
  } : {}

}

resource "azurerm_service_plan" "this" {
  count               = var.service_plan_id == null ? 1 : 0
  name                = "${var.function_app_name}-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "FC1"
  os_type             = "Linux"
}


resource "azurerm_function_app_flex_consumption" "this" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
  service_plan_id                   = var.service_plan_id == null ? azurerm_service_plan.this[0].id : var.service_plan_id
  storage_authentication_type       = "UserAssignedIdentity"
  storage_container_endpoint        = "${azurerm_storage_account.this.primary_blob_endpoint}${azurerm_storage_container.this.name}"
  storage_container_type            = "blobContainer"
  storage_user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  runtime_name                      = var.runtime_name
  runtime_version                   = var.runtime_version
  maximum_instance_count            = 40
  instance_memory_in_mb             = 2048

  app_settings = merge(local.base_app_settings, local.monitoring_app_settings)

  site_config {
    # ip_restriction {
    #   action = "Deny"
    #   description = "Default deny to block any incoming traffic into the azure function."
    #   ip_address = "0.0.0.0/0"
    #   priority = 65001
    # }
    # ip_restriction {
    #   action = "Allow"
    #   description = "Allow only a specific client ip to call the azure function."
    #   priority = 65000
    # }
  }
}