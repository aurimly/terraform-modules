terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   channels = {
#     "emails" = {
#       type         = "email"
#       display_name = "example-team-mailbox"
#       labels       = { email_address = "oncall@example.com" }
#     }
#   }
# }

inputs = {
  channels = {}
}
