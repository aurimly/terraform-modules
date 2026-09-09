terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   keyrings = {
#     "app" = {
#       name     = "example-app"
#       location = "us-central1"
#       keys = {
#         "gcs" = {
#           name            = "example-app-gcs"
#           purpose         = "ENCRYPT_DECRYPT"
#           rotation_period = "7776000s"
#           deletion_policy = "PREVENT"
#         }
#       }
#     },
#   }
# }

inputs = {
  keyrings = {}
}
