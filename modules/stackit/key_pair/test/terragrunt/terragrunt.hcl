terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   key_pairs = {
#     "deploy" = {
#       name       = "deploy-key"
#       public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterial comment@example"
#       labels = {
#         "env" = "prod"
#       }
#     },
#     "ci" = {
#       name       = "ci-key"
#       public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABExamplePublicKeyMaterial comment@example"
#     },
#   }
# }

inputs = {
  key_pairs = {}
}
