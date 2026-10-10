terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GitHub, replace the inputs
# below with real values (needs GITHUB_TOKEN and GITHUB_OWNER). terragrunt
# validate with an empty map needs no creds.
#
# inputs = {
#   branch_protections = {
#     "example-repo-main" = {
#       repository_id  = "R_exampleNodeId123"
#       branch         = "main"
#       enforce_admins = true
#       required_pull_request_reviews = {
#         required_approving_review_count = 2
#         dismiss_stale_reviews           = true
#       }
#       required_status_checks = {
#         strict   = true
#         contexts = ["ci/example"]
#       }
#     }
#   }
# }

inputs = {
  branch_protections = {}
}
