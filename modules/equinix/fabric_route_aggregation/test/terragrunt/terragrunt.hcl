terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Equinix, replace the inputs
# below with real values (needs Equinix creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   route_aggregations = {
#     "onprem-v4" = {
#       name = "example-ra-v4"
#       type = "BGP_IPv4_PREFIX_AGGREGATION"
#       project = {
#         project_id = "123456789012345"
#       }
#     },
#   }
#   rules = {
#     "branch-a" = {
#       aggregation_key = "onprem-v4"
#       name            = "example-branch-a"
#       prefix          = "192.168.0.0/24"
#     },
#   }
#   connection_attachments = {
#     "fcr-attach" = {
#       aggregation_key = "onprem-v4"
#       connection_id   = "87654321-4321-4321-4321-210987654321"
#     },
#   }
# }

inputs = {
  route_aggregations     = {}
  rules                  = {}
  connection_attachments = {}
}
