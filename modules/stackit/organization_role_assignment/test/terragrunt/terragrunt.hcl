terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   role_assignments = {
#     "org-admin" = {
#       resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       role        = "owner"
#       subject     = "jane.doe@example.com"
#     },
#   }
# }

inputs = {
  role_assignments = {}
}
