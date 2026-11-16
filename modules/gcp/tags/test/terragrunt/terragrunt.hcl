terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with the defaults
# needs no creds.
#
# inputs = {
#   tag_keys = {
#     "env" = {
#       parent     = "organizations/123456789012"
#       short_name = "environment"
#     }
#   }
#   tag_values = {
#     "prod" = {
#       key        = "env"
#       short_name = "production"
#     }
#   }
# }

inputs = {
  tag_keys   = {}
  tag_values = {}
}
