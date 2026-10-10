terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   repository = "example-repo"
#   deploy_keys = {
#     "ci-runner" = {
#       key       = "ssh-ed25519 AAAAC3Nz..."
#       read_only = true
#     }
#     "server-pull" = {
#       key   = "ssh-ed25519 AAAAB3Nz..."
#       title = "app server pull key"
#     }
#   }
# }

inputs = {
  repository  = "placeholder"
  deploy_keys = {}
}
