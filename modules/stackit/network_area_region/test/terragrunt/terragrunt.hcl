terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   network_area_regions = {
#     "eu01" = {
#       organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       network_area_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       region          = "eu01"
#       ipv4 = {
#         transfer_network = "10.1.2.0/24"
#         network_ranges = {
#           "prod" = "10.0.0.0/16"
#           "npd"  = "10.1.0.0/16"
#         }
#         default_nameservers   = ["192.0.2.1"]
#         default_prefix_length = 25
#         min_prefix_length     = 24
#         max_prefix_length     = 29
#       }
#     },
#   }
# }

inputs = {
  network_area_regions = {}
}
