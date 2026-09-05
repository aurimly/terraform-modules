terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   service_accounts = {
#     "ci-bot" = {
#       name       = "ci-bot"
#       project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#     },
#   }
# }

inputs = {
  service_accounts = {}
}
