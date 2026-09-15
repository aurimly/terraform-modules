terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   service_account_keys = {
#     "ci-bot" = {
#       project_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       service_account_email = "ci-bot-aBc2defg@sa.stackit.cloud"
#     },
#   }
# }

inputs = {
  service_account_keys = {}
}
