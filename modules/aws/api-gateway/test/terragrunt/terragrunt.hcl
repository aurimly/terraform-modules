terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   apis = {
#     "orders" = {
#       name = "example-orders"
#       cors_configuration = {
#         allow_origins = ["https://example.example"]
#         allow_methods = ["GET", "POST"]
#       }
#       authorizers = {
#         "cognito" = {
#           name             = "example-cognito"
#           identity_sources = ["$request.header.Authorization"]
#           jwt_configuration = {
#             issuer   = "https://cognito-idp.eu-central-1.amazonaws.com/example"
#             audience = ["example-client-id"]
#           }
#         }
#       }
#       integrations = {
#         "create-order" = {
#           integration_type       = "AWS_PROXY"
#           integration_uri        = "arn:aws:lambda:eu-central-1:111111111111:function:example-create-order"
#           payload_format_version = "2.0"
#         }
#       }
#       routes = {
#         "post-orders" = {
#           route_key       = "POST /orders"
#           integration_key = "create-order"
#         }
#       }
#       stage = {
#         name = "v1"
#         access_log_settings = {
#           destination_arn = "arn:aws:logs:eu-central-1:111111111111:log-group:/example/apigateway"
#           format          = "$context.identity.sourceIp $context.requestTime \"$context.routeKey\" $context.status"
#         }
#       }
#     }
#   }
#   domain_names = {
#     "orders" = {
#       domain_name     = "orders.example.example"
#       certificate_arn = "arn:aws:acm:eu-central-1:111111111111:certificate/00000000-0000-0000-0000-000000000000"
#       endpoint_type   = "REGIONAL"
#       security_policy = "TLS_1_2"
#     }
#   }
#   api_mappings = {
#     "orders" = {
#       api_key         = "orders"
#       domain_key      = "orders"
#       api_mapping_key = ""
#     }
#   }
# }

inputs = {
  apis         = {}
  domain_names = {}
  api_mappings = {}
}
