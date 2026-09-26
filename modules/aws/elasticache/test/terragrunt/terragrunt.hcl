terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   redis_clusters = {
#     "app-cache" = {
#       replication_group_id       = "example-app-cache"
#       node_type                  = "cache.t4g.small"
#       num_cache_clusters         = 2
#       automatic_failover_enabled = true
#       subnet_ids                 = ["subnet-12345678", "subnet-87654321"]
#     }
#   }
#   memcached_clusters = {
#     "sessions" = {
#       cluster_id     = "example-sessions"
#       node_type      = "cache.t4g.small"
#       num_cache_nodes = 2
#       subnet_ids     = ["subnet-12345678", "subnet-87654321"]
#       parameter_group_name = "default.memcached1.6"
#     }
#   }
# }

inputs = {
  redis_clusters     = {}
  memcached_clusters = {}
}
