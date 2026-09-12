terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   instances = {
#     "ops" = {
#       project_id             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       name                   = "example-observability"
#       plan_name              = "Observability-Starter-EU01"
#       acl                    = ["10.1.0.0/16"]
#       grafana_admin_enabled  = false
#       metrics_retention_days = 90
#       alert_config = {
#         receivers = [
#           {
#             name = "team-mail"
#             email_configs = [
#               {
#                 to       = "team@example.com"
#                 from     = "alerts@example.com"
#                 auth_username = "alerts@example.com"
#                 auth_password = "example-password"
#               },
#             ]
#           },
#         ]
#         route = {
#           receiver = "team-mail"
#         }
#       }
#     },
#   }
# }

inputs = {
  instances = {}
}
