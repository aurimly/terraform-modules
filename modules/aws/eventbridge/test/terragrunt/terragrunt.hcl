terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   event_buses = {
#     "orders" = {
#       name = "example-orders"
#       archives = {
#         "all" = {
#           name           = "example-orders-archive"
#           retention_days = 7
#         }
#       }
#     }
#   }
#   rules = {
#     "orders-created" = {
#       name          = "example-orders-created"
#       event_bus_key = "orders"
#       event_pattern = jsonencode({
#         source      = ["example.app"]
#         "detail-type" = ["order.created"]
#       })
#       targets = {
#         "jobs" = {
#           arn = "arn:aws:sqs:eu-central-1:111111111111:example-jobs"
#         }
#       }
#     }
#   }
#   schedules = {
#     "nightly" = {
#       name                = "example-nightly"
#       schedule_expression = "rate(1 day)"
#       target = {
#         arn      = "arn:aws:sqs:eu-central-1:111111111111:example-jobs"
#         role_arn = "arn:aws:iam::111111111111:role/example-scheduler"
#       }
#     }
#   }
#   schedule_groups = {
#     "ops" = {
#       name = "example-ops"
#     }
#   }
# }

inputs = {
  event_buses     = {}
  rules           = {}
  schedules       = {}
  schedule_groups = {}
}
