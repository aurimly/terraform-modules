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
#       name    = "example.com"
#       comment = "primary public zone"
#     },
#   }
# }

inputs = {
  zones = {}
}
