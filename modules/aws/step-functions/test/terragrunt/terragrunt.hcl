terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   state_machines = {
#     "orders" = {
#       name       = "example-orders"
#       role_arn   = "arn:aws:iam::123456789012:role/example-sfn"
#       definition = jsonencode({ StartAt = "Done", States = { Done = { Type = "Succeed" } } })
#       logging_configuration = {
#         log_destination = "arn:aws:logs:us-east-1:123456789012:log-group:example-orders:*"
#         level           = "ERROR"
#       }
#     },
#     "telemetry" = {
#       name_prefix = "example-telemetry-"
#       type        = "EXPRESS"
#       role_arn    = "arn:aws:iam::123456789012:role/example-sfn"
#       definition  = jsonencode({ StartAt = "Done", States = { Done = { Type = "Succeed" } } })
#       publish     = true
#     },
#   }
#   activities = {
#     "manual-review" = {
#       name = "example-manual-review"
#     }
#   }
# }

inputs = {
  state_machines = {}
  activities     = {}
}
