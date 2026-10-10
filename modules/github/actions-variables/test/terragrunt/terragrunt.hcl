terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   repository = "example-repo"
#   variables = {
#     "REGISTRY_URL" = { value = "registry.example.com" }
#     "DEPLOY_ENV"   = { value = "prod" }
#   }
# }

inputs = {
  repository = "placeholder"
  variables  = {}
}
