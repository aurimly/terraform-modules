terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with the defaults
# needs no creds.
#
# inputs = {
#   project_id = "my-project"
#   service_accounts = {
#     "app" = {
#       account_id   = "app-prod"
#       display_name = "App runtime"
#     }
#   }
# }

inputs = {
  project_id = "my-project"
}
