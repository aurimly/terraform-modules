terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   clusters = {
#     "main" = {
#       name       = "example-main"
#       role_arn   = dependency.iam_role.outputs.arns["cluster"]
#       version    = "1.34"
#       access_config = {
#         authentication_mode = "API"
#         bootstrap_cluster_creator_admin_permissions = true
#       }
#       create_oidc_provider = true
#       vpc_config = {
#         subnet_ids = dependency.network.outputs.private_subnet_ids
#         endpoint_private_access = true
#       }
#     },
#   }
#   node_groups = {
#     "system" = {
#       cluster_key   = "main"
#       name          = "example-system"
#       node_role_arn = dependency.iam_role.outputs.arns["worker"]
#       subnet_ids    = dependency.network.outputs.private_subnet_ids
#       scaling_config = {
#         desired_size = 2
#         min_size     = 1
#         max_size     = 3
#       }
#     },
#   }
# }

inputs = {
  clusters                   = {}
  node_groups                = {}
  addons                     = {}
  access_entries             = {}
  access_policy_associations = {}
}
