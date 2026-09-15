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
#       name = "example-bt-main"
#       clusters = {
#         "eu" = {
#           cluster_id = "example-bt-eu"
#           zone       = "europe-west4-a"
#           num_nodes  = 3
#         }
#       }
#     }
#   }
# }

inputs = {
  instances = {}
}
