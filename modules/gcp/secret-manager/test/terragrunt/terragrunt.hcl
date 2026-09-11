terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   secrets = {
#     "db-password" = {
#       secret_id = "example-db-password"
#       replication = {
#         user_managed = {
#           replicas = [
#             { location = "europe-west4" },
#             { location = "europe-west1" },
#           ],
#         },
#       },
#       versions = {
#         "1" = { secret_data = "example-value" },
#       },
#     },
#     "app-config" = {
#       secret_id = "example-app-config"
#       rotation = {
#         next_rotation_time = "2026-01-15T08:00:00Z"
#         rotation_period    = "2592000s",
#       },
#       topics = [
#         { name = "projects/example-prj/topics/example-secret-notifications" },
#       ],
#     },
#   }
# }

inputs = {
  secrets = {}
}
