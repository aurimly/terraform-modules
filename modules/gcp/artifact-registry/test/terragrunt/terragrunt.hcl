terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   repositories = {
#     "app-images" = {
#       repository_id = "app-images"
#       location      = "us-central1"
#       format        = "DOCKER"
#       docker_config = {
#         immutable_tags = true
#       }
#       role_bindings = {
#         "writers" = {
#           role    = "roles/artifactregistry.writer"
#           members = ["serviceAccount:ci@example-project-1234.iam.gserviceaccount.com"]
#         }
#       }
#     },
#   }
# }

inputs = {
  repositories = {}
}
