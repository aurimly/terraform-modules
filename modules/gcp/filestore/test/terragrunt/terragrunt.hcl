terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "shared-storage" = {
#       name     = "filestore-example-prd-01"
#       location = "europe-west4-a"
#       tier     = "BASIC_SSD"
#       file_shares = {
#         capacity_gb = 10240
#         name        = "share1"
#       }
#       networks = {
#         network           = "projects/example-network-project/global/networks/example-vpc"
#         modes             = ["MODE_IPV4"]
#         connect_mode      = "PRIVATE_SERVICE_ACCESS"
#         reserved_ip_range = "example-vpc-psc"
#       }
#     },
#   }
# }

inputs = {
  instances = {}
}
