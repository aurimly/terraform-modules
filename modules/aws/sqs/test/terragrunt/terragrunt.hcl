terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   queues = {
#     "jobs" = {
#       name                       = "example-jobs"
#       visibility_timeout_seconds = 300
#       redrive = {
#         dead_letter_target_arn = "arn:aws:sqs:eu-central-1:111111111111:example-jobs-dlq"
#         max_receive_count      = 5
#       }
#     },
#   }
# }

inputs = {
  queues = {}
}
