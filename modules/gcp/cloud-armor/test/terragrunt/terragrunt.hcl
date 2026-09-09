terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   security_policies = {
#     "example" = {
#       name = "example-cloudarmor"
#       ...
#     }
#   }
# }

inputs = {
  security_policies = {}
}
