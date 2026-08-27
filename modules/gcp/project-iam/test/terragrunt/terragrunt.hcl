terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with the defaults
# needs no creds.
#
# inputs = {
#   project_id = "my-project"
#   members = {
#     "viewer" = {
#       member = "group:platform@example.com"
#       roles  = ["roles/viewer"]
#     }
#   }
#   audit_configs = {
#     "all-services" = {
#       service = "allServices"
#       audit_log_configs = [
#         { log_type = "ADMIN_READ" },
#       ]
#     }
#   }
# }

inputs = {
  project_id = "my-project"
}
