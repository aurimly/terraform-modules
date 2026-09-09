terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   connections = {
#     "filestore" = {
#       network = "projects/example-network-project/global/networks/example-vpc"
#       allocate_ranges = {
#         "psc" = {
#           name          = "example-vpc-psc"
#           address       = "10.128.0.0"
#           prefix_length = 20
#         }
#       }
#       routes_config = {
#         import_custom_routes = true
#         export_custom_routes = true
#       }
#     },
#   }
# }

inputs = {
  connections = {}
}
