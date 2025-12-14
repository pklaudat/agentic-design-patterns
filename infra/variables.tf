
variable "project_name" {
  type        = string
  description = "Project name used as prefix for the resources naming convention."
}

variable "location" {
  type        = string
  description = "Location to place the azure resources."
}

variable "databases" {
  description = "Configuration for Cosmos DB databases."
  type = list(object({
    name       = string
    throughput = number
    containers = list(object({
      name          = string
      partition_key = string
      throughput    = number
      vector_embedding_policy = optional(list(object({
        path             = optional(string, "/vector")
        distanceFunction = optional(string, "cosine")
        dimensions       = optional(number, 1536)
        dataType         = optional(string, "float32")
      })), [])
      indexing_policy = object({
        automatic    = optional(bool, true)
        indexingMode = optional(string, "consistent")
        includedPaths = list(object({
          path = optional(string, "/*")
        }))
        excludedPaths = list(object({
          path = optional(string, "/\"_etag\"/?")
        }))
        vectorIndexes = optional(list(object({
          path = optional(string, "/vector"),
          type = optional(string, "quantizedFlat"),
        })), [])
      })
    }))
  }))
  default = []
}
