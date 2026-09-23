terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   keys = {
#     "app" = {
#       description         = "example app data encryption"
#       enable_key_rotation = true
#       aliases = {
#         "main" = { name = "alias/example-app" }
#       }
#     },
#   }
# }

inputs = {
  keys = {}
}
