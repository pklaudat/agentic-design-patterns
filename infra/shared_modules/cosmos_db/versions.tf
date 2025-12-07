terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 4.6"
        }
        azapi = {
            source  = "azure/azapi"
            version = "~> 2.7"
        }
    }
}