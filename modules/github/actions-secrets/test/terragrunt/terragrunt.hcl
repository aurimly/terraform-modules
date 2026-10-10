terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   repository = "example-repo"
#   secrets = {
#     "DEPLOY_TOKEN" = { value = "example-value" }
#     "API_KEY"      = { value = "example-key" }
#   }
# }

inputs = {
  repository = "placeholder"
  secrets    = {}
}
