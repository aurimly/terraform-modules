terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   jobs = {
#     "nightly-sync" = {
#       name     = "example-nightly-sync"
#       schedule = "0 3 * * *"
#       http_target = {
#         uri = "https://api.example.com/jobs/sync"
#       }
#     }
#   }
# }

inputs = {
  jobs = {}
}
