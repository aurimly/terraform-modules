terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   server_service_account_attaches = {
#     "backup-sa" = {
#       project_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region                = "eu01"
#       server_id             = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       service_account_email = "backup-sa-aBc2defg@sa.stackit.cloud"
#     },
#   }
# }

inputs = {
  server_service_account_attaches = {}
}
