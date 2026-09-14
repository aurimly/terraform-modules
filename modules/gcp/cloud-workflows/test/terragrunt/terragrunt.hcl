terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   workflows = {
#     "status-check" = {
#       name            = "example-status-check"
#       region          = "europe-west4"
#       source_contents = "- done:\n    return: true"
#     }
#   }
# }

inputs = {
  workflows = {}
}
