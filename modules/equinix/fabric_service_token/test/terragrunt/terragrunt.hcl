terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Equinix, replace the inputs
# below with real values (needs Equinix creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   service_tokens = {
#     "z-colo-token" = {
#       type                 = "VC_TOKEN"
#       name                 = "example-z-colo"
#       expiration_date_time = "2027-06-18T06:43:49.981Z"
#       notifications = [
#         {
#           type   = "ALL"
#           emails = ["ops@example.com"]
#         },
#       ]
#       connection = {
#         type                    = "EVPLAN_VC"
#         supported_bandwidths    = [50, 100, 200]
#         allow_remote_connection = true
#         z_side = {
#           access_point_selectors = [
#             {
#               type = "COLO"
#               port = {
#                 uuid = "12345678-1234-1234-1234-123456789012"
#               }
#               link_protocol = {
#                 type     = "DOT1Q"
#                 vlan_tag = 1234
#               }
#             },
#           ]
#         }
#       }
#     },
#   }
# }

inputs = {
  service_tokens = {}
}
