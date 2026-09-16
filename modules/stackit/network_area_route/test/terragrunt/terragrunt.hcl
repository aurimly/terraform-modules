terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   routes = {
#     "default-out" = {
#       organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       network_area_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       region          = "eu01"
#       destination = {
#         type  = "cidrv4"
#         value = "0.0.0.0/0"
#       }
#       next_hop = {
#         type = "internet"
#       }
#     }
#     "hub-branch" = {
#       organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       network_area_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       region          = "eu01"
#       destination = {
#         type  = "cidrv4"
#         value = "172.16.0.0/12"
#       }
#       next_hop = {
#         type  = "ipv4"
#         value = "192.0.2.1"
#       }
#     }
#   }
# }

inputs = {
  routes = {}
}
