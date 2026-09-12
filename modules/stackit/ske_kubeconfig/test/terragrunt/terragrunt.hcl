terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   kubeconfigs = {
#     "ci" = {
#       project_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       cluster_name = "example-prod"
#       region       = "eu01"
#       expiration   = 7200
#     },
#     "ops" = {
#       project_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       cluster_name   = "example-prod"
#       region         = "eu01"
#       expiration     = 7200
#       refresh        = true
#       refresh_before = 3600
#     },
#   }
# }

inputs = {
  kubeconfigs = {}
}
