
variable "function_app_name" {
  type        = string
  description = "The function app name."
}

variable "runtime_name" {
  type        = string
  description = "The runtime name."
  default     = "python"
}

variable "runtime_version" {
  type        = string
  description = "The runtime version."
  default     = "3.13"
}

variable "storage_account_name" {
  type        = string
  description = "The storage account name for this azure function."
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "The resource group name to host all resources in this module."
}

variable "location" {
  type        = string
  description = "The location for the resources."
}

variable "service_plan_id" {
  type        = string
  description = "External service plan resource id. By setting this variable the service plan won't be created."
  default     = null
}

variable "monitoring_enabled" {
  type        = bool
  description = "Enable monitoring via application insights."
  default     = false
}

variable "monitoring_workspace_id" {
  type        = string
  description = "Set log analytics workspace to use in monitoring layer."
  default     = null
}