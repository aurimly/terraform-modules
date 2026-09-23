terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   zones = {
#     "main" = {
#       zone_id = "Z0123456789ABCDEFGHIJ"
#       records = {
#         "apex-a" = {
#           name    = "example.com"
#           type    = "A"
#           ttl     = 300
#           records = ["203.0.113.10"]
#         }
#       }
#     },
#   }
# }

inputs = {
  zones = {}
}
