
variable "search_service_name" {
  description = "The name of the Azure Search Service."
  type        = string
}

variable "location" {
  description = "The Azure location where the Search Service will be created."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Search Service."
  type        = string
}