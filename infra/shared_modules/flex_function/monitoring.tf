
module "monitor" {
  count                      = var.monitoring_enabled ? 1 : 0
  source                     = "../monitor"
  monitor_prefix             = var.function_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.monitoring_workspace_id
  principal_id               = azurerm_user_assigned_identity.this.principal_id
}