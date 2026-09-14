terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   queues = {
#     "email-notifications" = {
#       name     = "example-email-notifications"
#       location = "europe-west4"
#       rate_limits = {
#         max_dispatches_per_second = 5
#       }
#     }
#   }
# }

inputs = {
  queues = {}
}
