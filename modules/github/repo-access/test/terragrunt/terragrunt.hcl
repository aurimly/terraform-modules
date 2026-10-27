terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   repositories = {
#     "example-repo" = {
#       repository = "example-repo"
#       teams = {
#         "platform" = {
#           team_id    = "1234567"
#           permission = "push"
#         }
#         "readers" = {
#           team_id    = "example-team"
#           permission = "pull"
#         }
#       }
#       users = {
#         "contractor-1" = {
#           username = "some-user"
#         }
#       }
#     }
#   }
# }

inputs = {
  repositories = {}
}
