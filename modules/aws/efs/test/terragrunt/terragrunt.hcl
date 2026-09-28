terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   file_systems = {
#     "data" = {
#       name       = "example-data"
#       kms_key_id = dependency.kms.outputs.key_arns["efs"]
#       lifecycle_policy = {
#         transition_to_ia = "AFTER_30_DAYS"
#       }
#       backup_policy = {
#         status = "ENABLED"
#       }
#     },
#   }
#   mount_targets = {
#     "az-a" = {
#       fs_key             = "data"
#       subnet_id          = dependency.network.outputs.private_subnet_ids["a"]
#       security_group_ids = dependency.security_groups.outputs.security_group_ids["efs"]
#     },
#   }
#   access_points = {
#     "app-data" = {
#       fs_key = "data"
#       posix_user = {
#         uid = 1000
#         gid = 1000
#       }
#       root_directory = {
#         path = "/app"
#         creation_info = {
#           owner_uid   = 1000
#           owner_gid   = 1000
#           permissions = "0755"
#         }
#       }
#     },
#   }
# }

inputs = {
  file_systems  = {}
  mount_targets = {}
  access_points = {}
}
