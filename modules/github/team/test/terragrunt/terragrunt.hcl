terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   teams = {
#     "platform" = {
#       name        = "Platform"
#       description = "Platform engineering"
#       privacy     = "closed"
#       members = {
#         "dev-1" = {
#           username = "dev-one"
#           role     = "maintainer"
#         }
#         "dev-2" = {
#           username = "dev-two"
#         }
#       }
#     },
#     "platform-sre" = {
#       name            = "Platform SRE"
#       parent_team_key = "platform"
#       privacy         = "closed"
#       members = {
#         "sre-1" = {
#           username = "sre-one"
#         }
#       }
#     }
#   }
# }

inputs = {
  teams = {}
}
