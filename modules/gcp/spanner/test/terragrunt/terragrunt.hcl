terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "example" = {
#       name             = "example-sp-main"
#       display_name     = "Example Spanner"
#       config           = "regional-europe-west1"
#       processing_units = 1000
#     }
#   }
# }

inputs = {
  instances = {}
}
