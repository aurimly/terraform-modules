terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   services = {
#     "pubsub-prod" = {
#       project_id = "example-project-1234"
#       service    = "pubsub.googleapis.com"
#     },
#     "storage-prod" = {
#       project_id         = "example-project-1234"
#       service            = "storage.googleapis.com"
#       disable_on_destroy = true
#     },
#   }
# }

inputs = {
  services = {}
}
