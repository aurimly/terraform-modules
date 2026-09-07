terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   buckets = {
#     "logs" = {
#       name       = "example-project-1234-logs"
#       location   = "us-central1"
#       versioning = true,
#       lifecycle_rules = [
#         {
#           action    = { type = "Delete" }
#           condition = { age = 90 }
#         },
#         {
#           action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
#           condition = { age = 30, matches_storage_class = ["STANDARD"] }
#         },
#       ],
#       role_bindings = {
#         "viewers" = {
#           role    = "roles/storage.objectViewer"
#           members = ["group:example-viewers@example.com"]
#         },
#       },
#     },
#     "assets" = {
#       name               = "example-assets"
#       location           = "US"
#       autoclass          = { enabled = true },
#       soft_delete_policy = { retention_duration_seconds = 0 },
#       cors = [
#         { origin = ["https://example.org"], method = ["GET"], max_age_seconds = 3600 },
#       ],
#     },
#   }
# }

inputs = {
  buckets = {}
}
