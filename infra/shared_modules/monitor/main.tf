resource "azurerm_log_analytics_workspace" "this" {
  name                         = "${var.monitor_prefix}-logs"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku                          = "PerGB2018"
  retention_in_days            = 30
  local_authentication_enabled = false
}

resource "azurerm_application_insights" "this" {
  name                          = "${var.monitor_prefix}-insights"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_type              = "other"
  workspace_id                  = azurerm_log_analytics_workspace.this.id
  local_authentication_disabled = true
}

resource "azurerm_role_assignment" "this" {
  principal_id         = var.principal_id
  scope                = azurerm_application_insights.this.id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Monitoring Metrics Publisher"
}


