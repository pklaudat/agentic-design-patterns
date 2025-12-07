variable "cosmos_db_account_name" {
  description = "The name of the Cosmos DB account."
  type        = string
}

variable "location" {
  description = "The Azure region where the Cosmos DB account will be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Cosmos DB account."
  type        = string
}

variable "ip_range_filter" {
  description = "A list of IP ranges to allow access to the Cosmos DB account."
  type        = list(string)
  default     = []
}

variable "throughput" {
  description = "The throughput of the Cosmos DB SQL database."
  type        = number
  default     = 400
}

variable "databases_config" {
  description = "Configuration for Cosmos DB databases."
  type = list(object({
    name       = string
    throughput = number
    containers = list(object({
      name             = string
      partition_key    = string
      throughput       = number
      vector_embedding_policy = optional(list(object({
        path       = optional(string, "/vector")
        distanceFunction = optional(string, "cosine")
        dimensions = optional(number, 1536)
        dataType   = optional(string, "float32")
      })), [])
      indexing_policy  = object({
        automatic     = optional(bool, true)
        indexingMode  = optional(string, "consistent")
        includedPaths = list(object({
          path = optional(string, "/*")
        }))
        excludedPaths = list(object({
          path = optional(string, "/\"_etag\"/?")
        }))
        vectorIndexes = optional(list(object({
          path          = optional(string, "/vector"),
          type     = optional(string, "quantizedFlat"),
        })), [])
      })
    })) 
  }))
  default = []
}


variable "free_tier_enabled" {
  description = "Enable free tier for the Cosmos DB account."
  type        = bool
  default     = false
}