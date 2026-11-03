terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   groups = {
#     "deployers" = {
#       name = "example-deployers"
#       managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
#     },
#     "log-watchers" = {
#       name = "example-log-watchers"
#       inline_policies = {
#         "read-logs" = {
#           name        = "example-read-logs"
#           policy_json = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["logs:GetLogEvents"], Resource = "*" }] })
#         },
#       }
#     },
#   }
# }

inputs = {
  groups = {}
}
