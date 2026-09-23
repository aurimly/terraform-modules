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
#       name                = "example-main"
#       capacity_providers  = ["FARGATE", "FARGATE_SPOT"]
#       default_capacity_provider_strategy = [
#         { capacity_provider = "FARGATE", weight = 1 }
#       ]
#     },
#   }
# }

inputs = {
  clusters = {}
}
