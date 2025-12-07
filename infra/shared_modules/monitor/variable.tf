

variable "monitor_prefix" {
  type        = string
  description = "Standard name to build azure monitor resources."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "External log analytics workspace id."
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


variable "principal_id" {
  type        = string
  description = "The principal id to access this service."
}