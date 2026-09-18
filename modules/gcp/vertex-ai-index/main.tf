resource "google_vertex_ai_index" "index" {
  for_each = var.indexes

  display_name        = each.value.display_name
  region              = each.value.region
  project             = each.value.project_id
  description         = each.value.description
  labels              = each.value.labels
  index_update_method = each.value.index_update_method
  deletion_policy     = each.value.deletion_policy

  dynamic "encryption_spec" {
    for_each = each.value.encryption_spec != null ? [each.value.encryption_spec] : []

    content {
      kms_key_name = encryption_spec.value.kms_key_name
    }
  }

  dynamic "metadata" {
    for_each = [each.value.metadata]

    content {
      contents_delta_uri    = metadata.value.contents_delta_uri
      is_complete_overwrite = metadata.value.is_complete_overwrite

      dynamic "config" {
        for_each = [metadata.value.config]

        content {
          dimensions                  = config.value.dimensions
          approximate_neighbors_count = config.value.approximate_neighbors_count
          shard_size                  = config.value.shard_size
          distance_measure_type       = config.value.distance_measure_type
          feature_norm_type           = config.value.feature_norm_type

          dynamic "algorithm_config" {
            for_each = config.value.algorithm_config != null ? [config.value.algorithm_config] : []

            content {
              dynamic "tree_ah_config" {
                for_each = algorithm_config.value.tree_ah_config != null ? [algorithm_config.value.tree_ah_config] : []

                content {
                  leaf_node_embedding_count    = tree_ah_config.value.leaf_node_embedding_count
                  leaf_nodes_to_search_percent = tree_ah_config.value.leaf_nodes_to_search_percent
                }
              }

              dynamic "brute_force_config" {
                for_each = algorithm_config.value.brute_force_config != null ? [algorithm_config.value.brute_force_config] : []

                content {}
              }
            }
          }
        }
      }
    }
  }
}
