terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   folders = {
#     "example-team" = {
#       name                = "team-a"
#       owner_email         = "team-owner@example.com"
#       parent_container_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#     },
#     "example-env" = {
#       name                = "prod"
#       owner_email         = "team-owner@example.com"
#       parent_container_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       labels = {
#         "env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  folders = {}
}
