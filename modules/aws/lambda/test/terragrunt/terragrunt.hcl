terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   functions = {
#     "orders" = {
#       name     = "example-orders"
#       role_arn = "arn:aws:iam::123456789012:role/example-lambda-exec"
#       runtime  = "python3.13"
#       handler  = "app.handler"
#       s3_bucket = "example-artifacts"
#       s3_key    = "orders.zip"
#       event_source_mappings = {
#         "jobs" = {
#           event_source_arn = "arn:aws:sqs:us-east-1:123456789012:example-jobs"
#         }
#       }
#     },
#   }
# }

inputs = {
  functions = {}
}
