project_name = "agent-learn-pk"
location     = "centralus"
databases = [{
    name       = "vectorSearchDB"
    throughput = 400
    containers = [{
      name          = "Movies"
      partition_key = "/id"
      throughput    = 400
      vector_embedding_policy = [{
        path             = "/vector"
        distanceFunction = "cosine"
        dimensions       = 1536
        dataType         = "float32"
      }]
      indexing_policy = {
        includedPaths = [{
          path = "/*"
        }]
        excludedPaths = [{
          path = "/\"_etag\"/?"
          }, {
          path = "/vector/*"
        }]
        vectorIndexes = [{
          path = "/vector"
          type = "quantizedFlat"
        }]
      }
    }]
  }]