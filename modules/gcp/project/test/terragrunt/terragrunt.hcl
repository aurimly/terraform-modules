terraform {
  source = "../../"
}

# Example inputs (commented). billing_account is required by the module schema.
# To validate against GCP, replace the inputs below with real values (needs
# GCP creds). terragrunt validate with an empty map needs no creds.
#
# inputs = {
#   projects = {
#     "example-one" = {
#       name            = "example-one"
#       project_id      = "example-one-1234"
#       org_id          = "123456789012"
#       billing_account = "01AB23-CD45EF-67GH89"
#       deletion_policy = "PREVENT"
#       labels = {
#         env = "test"
#       }
#     },
#     "example-two" = {
#       name            = "example-two"
#       project_id      = "example-two-5678"
#       folder_id       = "folders/9876543210"
#       billing_account = "01AB23-CD45EF-67GH89"
#       labels = {
#         env = "prod"
#       }
#       tags = {
#         "123456789012/env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  projects = {}
}
