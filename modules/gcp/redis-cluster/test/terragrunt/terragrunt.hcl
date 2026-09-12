terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "example" = {
#       name        = "example-cache"
#       location    = "europe-west4"
#       shard_count = 3
#       node_type   = "SHARED_CORE_NANO"
#     }
#   }
# }

inputs = {
  instances = {}
}
