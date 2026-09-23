terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   buckets = {
#     "logs" = {
#       name = "example-logs"
#       public_access_block = {
#         block_public_acls       = true
#         block_public_policy     = true
#         ignore_public_acls      = true
#         restrict_public_buckets = true
#       }
#     }
#   }
# }

inputs = {
  buckets = {}
}
