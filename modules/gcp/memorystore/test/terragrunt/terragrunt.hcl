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
#       name           = "example-cache"
#       region         = "europe-west4"
#       memory_size_gb = 5
#       redis_version  = "REDIS_7_0"
#     }
#   }
# }

inputs = {
  instances = {}
}
