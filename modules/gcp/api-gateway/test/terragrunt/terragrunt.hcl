terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with the defaults
# needs no creds.
#
# inputs = {
#   apis = {
#     "catalog" = {
#       api_id = "catalog-api"
#     }
#   }
#   api_configs = {
#     "v1" = {
#       api           = "catalog"
#       api_config_id = "catalog-v1"
#       openapi_documents = [
#         {
#           document = {
#             path     = "spec.yaml"
#             contents = filebase64("spec.yaml")
#           }
#         }
#       ]
#     }
#   }
#   gateways = {
#     "prod" = {
#       api_config_key = "v1"
#       gateway_id     = "catalog-gateway"
#       region         = "europe-west4"
#     }
#   }
# }

inputs = {
  apis        = {}
  api_configs = {}
  gateways    = {}
}
