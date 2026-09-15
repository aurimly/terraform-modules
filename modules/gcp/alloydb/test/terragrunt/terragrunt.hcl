terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   clusters = {
#     "example" = {
#       cluster_id = "example-app-cluster"
#       location   = "europe-west4"
#       instances = {
#         "primary" = {
#           instance_id   = "example-app-primary"
#           instance_type = "PRIMARY"
#         }
#       }
#     }
#   }
# }

inputs = {
  clusters = {}
}
