terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   endpoints = {
#     "serving" = {
#       name         = "1234567890"
#       display_name = "example-endpoint"
#       location     = "europe-west4"
#       network      = "projects/123456789012/global/networks/vpc-example"
#       traffic_split = {
#         "12345" = 100
#       }
#     }
#   }
#   model_garden_deployments = {
#     "gemma" = {
#       publisher_model_name = "publishers/google/models/gemma@gemma-1.1-2b-it"
#       location             = "europe-west4"
#       model_config = {
#         accept_eula = true
#       }
#     }
#   }
# }

inputs = {
  endpoints                = {}
  model_garden_deployments = {}
}
