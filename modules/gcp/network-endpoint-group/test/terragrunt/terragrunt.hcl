terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   negs = {
#     "hybrid" = {
#       name = "example-hybrid-neg"
#       zone = "us-central1-a"
#     }
#   }
#   endpoints = {
#     "one" = {
#       neg        = "hybrid"
#       ip_address = "10.10.0.10"
#       port       = 8080
#       instance   = "example-instance-1"
#     }
#   }
# }

inputs = {
  negs          = {}
  regional_negs = {}
  endpoints     = {}
}
