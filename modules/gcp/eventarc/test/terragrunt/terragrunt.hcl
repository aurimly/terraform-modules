terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   triggers = {
#     "pubsub-to-runner" = {
#       name     = "example-pubsub-to-runner"
#       location = "us-central1"
#       pubsub_topic = "projects/example-prj/topics/example-inbound"
#       matching_criteria = [
#         { attribute = "type", value = "google.cloud.pubsub.topic.v1.messagePublished" }
#       ]
#       cloud_run_service = {
#         service = "example-runner"
#         region  = "us-central1"
#       }
#     },
#   }
# }

inputs = {
  triggers = {}
}
