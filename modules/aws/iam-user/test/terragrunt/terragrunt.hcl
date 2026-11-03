terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   users = {
#     "ci-deployer" = {
#       name   = "example-ci-deployer"
#       groups = ["example-deployers"]
#     },
#     "ci-reporter" = {
#       name                = "example-ci-reporter"
#       access_key          = { pgp_key = "keybase:example_owner" }
#       managed_policy_arns = ["arn:aws:iam::aws:policy/IAMReadOnlyAccess"]
#     },
#   }
# }

inputs = {
  users = {}
}
