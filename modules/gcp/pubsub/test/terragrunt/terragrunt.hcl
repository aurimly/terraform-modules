terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   topics = {
#     "events" = {
#       name       = "example-events"
#       project_id = "example-prj"
#       message_storage_policy = {
#         allowed_persistence_regions = ["europe-west4"]
#         enforce_in_transit          = true,
#       },
#       subscriptions = {
#         "webhooks" = {
#           name                 = "example-webhooks"
#           ack_deadline_seconds = 30
#           push_config = {
#             push_endpoint = "https://example.net/hooks"
#             oidc_token = {
#               service_account_email = "sa-webhook-rt@example-prj.iam.gserviceaccount.com"
#             },
#           },
#           retry_policy = {
#             minimum_backoff = "10s"
#             maximum_backoff = "300s",
#           },
#           dead_letter_policy = {
#             dead_letter_topic     = "projects/example-prj/topics/example-dlq"
#             max_delivery_attempts = 10,
#           },
#         },
#       },
#     },
#   }
# }

inputs = {
  topics = {}
}
