terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   secrets = {
#     "db-password" = {
#       name                    = "example-db-password"
#       description             = "example database password"
#       recovery_window_in_days = 7
#       secret_string           = jsonencode({ engine = "postgres", host = "example.db", username = "app", password = "example-value" })
#       replicas = {
#         "eu-west-1" = { region = "eu-west-1" }
#       }
#       rotation = {
#         rotation_lambda_arn = "arn:aws:lambda:eu-central-1:111111111111:function:example-rotation"
#         rotation_rules = {
#           automatically_after_days = 30
#         }
#       }
#       tags = {
#         Environment = "example"
#       }
#     }
#     "api-key" = {
#       name = "example-api-key"
#     }
#   }
# }

inputs = {
  secrets = {}
}
