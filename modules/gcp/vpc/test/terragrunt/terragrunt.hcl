terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   networks = {
#     "example-vpc" = {
#       name                    = "example-vpc"
#       project_id              = "example-project-1234"
#       description             = "Example VPC"
#       auto_create_subnetworks = false
#       routing_mode            = "REGIONAL"
#       mtu                     = 1460
#     },
#   }
# }

inputs = {
  networks = {}
}
