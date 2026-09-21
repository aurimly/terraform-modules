terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Equinix, replace the inputs
# below with real values (needs Equinix creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   connections = {
#     "example-fcr-to-sp" = {
#       name      = "example-fcr-sp"
#       type      = "IP_VC"
#       bandwidth = 50
#       notifications = [
#         {
#           type   = "ALL"
#           emails = ["ops@example.com"]
#         },
#       ]
#       a_side = {
#         access_point = {
#           type   = "CLOUD_ROUTER"
#           router = {
#             uuid = "12345678-1234-1234-1234-123456789012"
#           }
#         }
#       }
#       z_side = {
#         access_point = {
#           type               = "SP"
#           authentication_key = "example-auth-key"
#           profile = {
#             type = "L2_PROFILE"
#             uuid = "87654321-4321-4321-4321-210987654321"
#           }
#           location = {
#             metro_code = "SV"
#           }
#         }
#       }
#     },
#   }
# }

inputs = {
  connections = {}
}
