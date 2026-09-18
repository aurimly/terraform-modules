variable "indexes" {
  description = "Map of Vertex AI Vector Search indexes keyed by an arbitrary identifier. Each entry creates one google_vertex_ai_index. Index contents (GCS delta files) are managed outside the module; pair with gcp/bucket."
  type = map(object({
    display_name        = string
    region              = optional(string)
    project_id          = optional(string)
    description         = optional(string)
    labels              = optional(map(string), {})
    index_update_method = optional(string)
    deletion_policy     = optional(string)
    encryption_spec = optional(object({
      kms_key_name = string
    }))
    metadata = object({
      contents_delta_uri    = string
      is_complete_overwrite = optional(bool)
      config = object({
        dimensions                  = number
        approximate_neighbors_count = optional(number)
        shard_size                  = optional(string)
        distance_measure_type       = optional(string)
        feature_norm_type           = optional(string)
        algorithm_config = optional(object({
          tree_ah_config = optional(object({
            leaf_node_embedding_count    = optional(number)
            leaf_nodes_to_search_percent = optional(number)
          }))
          brute_force_config = optional(object({}))
        }))
      })
    })
  }))

  validation {
    condition     = alltrue([for k, i in var.indexes : i.index_update_method == null || contains(["BATCH_UPDATE", "STREAM_UPDATE"], i.index_update_method)])
    error_message = "index_update_method must be BATCH_UPDATE or STREAM_UPDATE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : can(regex("^gs://", i.metadata.contents_delta_uri))])
    error_message = "metadata.contents_delta_uri must be a gs:// Cloud Storage directory path; the Matching Engine API requires it when creating an index."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : i.metadata.config.dimensions >= 1])
    error_message = "metadata.config.dimensions must be at least 1."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : i.metadata.config.shard_size == null || contains(["SHARD_SIZE_SMALL", "SHARD_SIZE_MEDIUM", "SHARD_SIZE_LARGE"], i.metadata.config.shard_size)])
    error_message = "metadata.config.shard_size must be one of SHARD_SIZE_SMALL, SHARD_SIZE_MEDIUM or SHARD_SIZE_LARGE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : i.metadata.config.distance_measure_type == null || contains(["SQUARED_L2_DISTANCE", "L1_DISTANCE", "COSINE_DISTANCE", "DOT_PRODUCT_DISTANCE"], i.metadata.config.distance_measure_type)])
    error_message = "metadata.config.distance_measure_type must be one of SQUARED_L2_DISTANCE, L1_DISTANCE, COSINE_DISTANCE or DOT_PRODUCT_DISTANCE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : i.metadata.config.feature_norm_type == null || contains(["UNIT_L2_NORM", "NONE"], i.metadata.config.feature_norm_type)])
    error_message = "metadata.config.feature_norm_type must be UNIT_L2_NORM or NONE (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.indexes : i.metadata.config.algorithm_config == null || alltrue([
        length([for b in ["tree_ah_config", "brute_force_config"] : b if i.metadata.config.algorithm_config[b] != null]) <= 1,
        i.metadata.config.algorithm_config.tree_ah_config == null || i.metadata.config.approximate_neighbors_count != null,
      ])
    ])
    error_message = "algorithm_config must set at most one of tree_ah_config or brute_force_config; tree_ah_config requires metadata.config.approximate_neighbors_count (the API rejects tree-AH without it)."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : i.metadata.config.algorithm_config == null || i.metadata.config.algorithm_config.tree_ah_config == null || i.metadata.config.algorithm_config.tree_ah_config.leaf_nodes_to_search_percent == null || (i.metadata.config.algorithm_config.tree_ah_config.leaf_nodes_to_search_percent >= 1 && i.metadata.config.algorithm_config.tree_ah_config.leaf_nodes_to_search_percent <= 100)])
    error_message = "algorithm_config.tree_ah_config.leaf_nodes_to_search_percent must be in range 1-100 when set."
  }

  validation {
    condition     = alltrue([for k, i in var.indexes : i.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], i.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, i in var.indexes : alltrue(flatten([
        for kk, v in i.labels : [
          length(kk) <= 64,
          length(v) <= 64,
          !can(regex("[A-Z ]", kk)),
          !can(regex("[A-Z ]", v)),
        ]
      ]))
    ])
    error_message = "labels keys and values must be at most 64 characters and contain no uppercase ASCII letters or spaces (international characters are allowed, matching the provider)."
  }
}
