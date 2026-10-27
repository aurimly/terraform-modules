terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   members = {
#     "dev-1" = {
#       username = "dev-one"
#     }
#     "owner-1" = {
#       username = "owner-one"
#       role     = "admin"
#     }
#   }
# }

inputs = {
  members = {}
}
