terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   repository = "example-repo"
#   environments = {
#     "dev" = {
#       environment = "dev"
#       deployment_branch_policy = {
#         protected_branches     = true
#         custom_branch_policies = false
#       }
#       variables = {
#         "DEPLOY_ENV" = { value = "dev" }
#       }
#     },
#     "prod" = {
#       environment         = "prod"
#       wait_timer          = 300
#       prevent_self_review = true
#       reviewers = {
#         users = [1234567]
#         teams = [7654321]
#       }
#       deployment_branch_policy = {
#         custom_branch_policies = true
#         branch_patterns        = ["main", "release/*"]
#       }
#       secrets = {
#         "DEPLOY_TOKEN" = { value = "example-value" }
#       }
#     }
#   }
# }

inputs = {
  repository   = "placeholder"
  environments = {}
}
