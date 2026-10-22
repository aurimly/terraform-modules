terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   ip_sets = {
#     "corporate" = {
#       name               = "example-office-ranges"
#       scope              = "REGIONAL"
#       ip_address_version = "IPV4"
#       addresses          = ["198.51.100.0/24"]
#     }
#   }
#   web_acls = {
#     "edge" = {
#       name  = "example-edge-acl"
#       scope = "CLOUDFRONT"
#       default_action = "allow"
#       visibility_config = {
#         cloudwatch_metrics_enabled = true
#         metric_name                = "example_edge_acl"
#         sampled_requests_enabled   = false
#       }
#       rules = {
#         "common" = {
#           name            = "example-common"
#           priority        = 0
#           override_action = "none"
#           statement = {
#             managed_rule_group = {
#               vendor_name = "AWS"
#               name        = "AWSManagedRulesCommonRuleSet"
#             }
#           }
#           visibility_config = {
#             cloudwatch_metrics_enabled = true
#             metric_name                = "example_edge_common"
#             sampled_requests_enabled   = false
#           }
#         }
#       }
#     }
#     "internal" = {
#       name  = "example-internal-acl"
#       scope = "REGIONAL"
#       visibility_config = {
#         cloudwatch_metrics_enabled = true
#         metric_name                = "example_internal_acl"
#         sampled_requests_enabled   = false
#       }
#       rules = {
#         "rate" = {
#           name     = "example-rate"
#           priority = 0
#           action   = "count"
#           statement = {
#             rate_based = {
#               limit = 2000
#             }
#           }
#           visibility_config = {
#             cloudwatch_metrics_enabled = true
#             metric_name                = "example_internal_rate"
#             sampled_requests_enabled   = false
#           }
#         }
#       }
#     }
#   }
#   associations = {
#     "alb" = {
#       web_acl_key  = "internal"
#       resource_arn = "arn:aws:elasticloadbalancing:eu-central-1:111111111111:loadbalancer/app/example/0000000000000000"
#     }
#   }
# }

inputs = {
  ip_sets      = {}
  web_acls     = {}
  rule_groups  = {}
  associations = {}
}
