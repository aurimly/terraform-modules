terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Equinix, replace the inputs
# below with real values (needs Equinix creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   cloud_routers = {
#     "example" = {
#       name   = "example-fcr"
#       type   = "XF_ROUTER"
#       location = {
#         metro_code = "SV"
#       }
#       package = {
#         code = "STANDARD"
#       }
#       project = {
#         project_id = "123456789012345"
#       }
#       notifications = [
#         {
#           type   = "ALL"
#           emails = ["ops@example.com"]
#         },
#       ]
#     },
#   }
# }

inputs = {
  cloud_routers = {}
}
