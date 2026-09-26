terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   log_groups = {
#     "app-http" = {
#       name              = "/example/app/http"
#       retention_in_days = 30
#     }
#   }
#   metric_alarms = {
#     "app-5xx" = {
#       alarm_name          = "example-alb-5xx-high"
#       namespace           = "AWS/ApplicationELB"
#       metric_name         = "HTTPCode_Target_5XX_Count"
#       dimensions          = { LoadBalancer = "app/example/123" }
#       statistic           = "Sum"
#       period              = 60
#       evaluation_periods  = 5
#       threshold           = 10
#       comparison_operator = "GreaterThanThreshold"
#     }
#   }
#   dashboards = {
#     "app" = {
#       dashboard_name = "example-app"
#       dashboard_body = jsonencode({ widgets = [] })
#     }
#   }
# }

inputs = {
  log_groups    = {}
  metric_alarms = {}
  dashboards    = {}
}
