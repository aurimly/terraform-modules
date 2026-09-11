terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   zones = {
#     "public" = {
#       name     = "example-org-public"
#       dns_name = "example.org."
#     }
#   }
# }

inputs = {
  zones = {}
}
