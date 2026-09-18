terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   indexes = {
#     "treeah" = {
#       display_name       = "example-treeah-index"
#       region             = "europe-west4"
#       metadata = {
#         contents_delta_uri = "gs://example-bucket/index-delta"
#         config = {
#           dimensions                  = 128
#           approximate_neighbors_count = 100
#           shard_size                  = "SHARD_SIZE_SMALL"
#           algorithm_config = {
#             tree_ah_config = {
#               leaf_node_embedding_count    = 1000
#               leaf_nodes_to_search_percent = 10
#             }
#           }
#         }
#       }
#     }
#   }
# }

inputs = {
  indexes = {}
}
