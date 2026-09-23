terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   tables = {
#     "sessions" = {
#       name           = "example-sessions"
#       hash_key       = "user_id"
#       attributes = {
#         "user_id" = { type = "S" }
#       }
#     }
#   }
# }

inputs = {
  tables = {}
}
