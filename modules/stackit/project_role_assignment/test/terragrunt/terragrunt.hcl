terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   role_assignments = {
#     "project-owner" = {
#       resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       role        = "owner"
#       subject     = "jane.doe@example.com"
#     },
#     "auditor" = {
#       resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       role        = "reader"
#       subject     = "audit-bot@example.com"
#     },
#   }
# }

inputs = {
  role_assignments = {}
}
