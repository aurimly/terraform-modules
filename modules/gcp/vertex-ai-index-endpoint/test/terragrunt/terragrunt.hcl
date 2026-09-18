terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   index_endpoints = {
#     "psa" = {
#       display_name = "example-psa-endpoint"
#       region       = "europe-west4"
#       network      = "projects/123456789012/global/networks/vpc-example"
#     }
#   }
#   deployed_indexes = {
#     "auto" = {
#       deployed_index_id = "example_deployed"
#       index             = "projects/example-prj/locations/europe-west4/indexes/12345"
#       index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
#       automatic_resources = {
#         min_replica_count = 2
#       }
#     }
#   }
# }

inputs = {
  index_endpoints  = {}
  deployed_indexes = {}
}
