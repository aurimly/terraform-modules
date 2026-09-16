terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   triggers = {
#     "push-main" = {
#       name     = "example-push-main"
#       location = "us-central1"
#       filename = "cloudbuild.yaml"
#       github = {
#         owner = "example-org"
#         name  = "example-repo"
#         push = {
#           branch = "^main$"
#         }
#       }
#     },
#   }
# }

inputs = {
  triggers = {}
}
