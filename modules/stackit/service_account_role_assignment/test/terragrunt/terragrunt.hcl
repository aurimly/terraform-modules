terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# Act-As: the subject may act as (impersonate) the target service account.
# The typical real-world case is the SKE service account (its email ends in
# @ske.sa.stackit.cloud).
#
# inputs = {
#   role_assignments = {
#     "ske-act-as" = {
#       resource_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       role        = "user"
#       subject     = "ske-bot@example.com"
#     },
#   }
# }

inputs = {
  role_assignments = {}
}
