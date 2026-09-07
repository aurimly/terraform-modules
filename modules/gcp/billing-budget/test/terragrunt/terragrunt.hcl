terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   budgets = {
#     "prod-monthly" = {
#       billing_account = "A1B2C3-D4E5F6-G7H8I9"
#       display_name    = "example-prod-monthly"
#       amount = {
#         specified_amount = {
#           currency_code = "USD"
#           units         = "1000"
#         }
#       },
#       budget_filter = {
#         calendar_period = "MONTH"
#         projects        = ["projects/123456789012"]
#       },
#       threshold_rules = [
#         { threshold_percent = 0.5 },
#         { threshold_percent = 0.9, spend_basis = "FORECASTED_SPEND" },
#       ],
#       all_updates_rule = {
#         monitoring_notification_channels = ["projects/example-project-1234/notificationChannels/abc123"]
#       },
#     },
#     "npd-last-period" = {
#       billing_account = "A1B2C3-D4E5F6-G7H8I9"
#       display_name    = "example-npd-last-period"
#       amount = {
#         last_period_amount = true
#       },
#     },
#   }
# }

inputs = {
  budgets = {}
}
