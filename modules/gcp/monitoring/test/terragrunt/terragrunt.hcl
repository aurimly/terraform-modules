terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   dashboards = {
#     "main" = {
#       dashboard_json = jsonencode({ displayName = "Example dashboards" })
#     }
#   }
#   alert_policies = {
#     "latency" = {
#       display_name = "example-api latency"
#       combiner     = "OR"
#       conditions   = []
#     }
#   }
# }

inputs = {
  dashboards     = {}
  alert_policies = {}
}
