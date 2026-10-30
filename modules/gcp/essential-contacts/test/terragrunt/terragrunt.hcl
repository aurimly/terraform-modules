terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   contacts = {
#     "security" = {
#       email                               = "sec@example.com"
#       parent                              = "organizations/123456789012"
#       notification_category_subscriptions = ["SECURITY"]
#     },
#     "technical" = {
#       email                               = "ops@example.com"
#       parent                              = "organizations/123456789012"
#       notification_category_subscriptions = ["TECHNICAL"]
#     },
#   }
# }

inputs = {
  contacts = {}
}
