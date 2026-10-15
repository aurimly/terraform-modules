terraform {
  source = "../../"
}

# Example inputs (commented). To plan against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   policies = {
#     "web" = {
#       name                = "wafp-web-prod"
#       resource_group_name = "rg-network-prod"
#       location            = "westeurope"
#
#       managed_rule_sets = {
#         "owasp" = {
#           type    = "OWASP"
#           version = "3.2"
#
#           rule_group_overrides = {
#             "protocol-enforcement" = {
#               rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
#
#               rules = {
#                 "920300" = {
#                   id     = "920300"
#                   action = "Log"
#                 }
#               }
#             }
#           }
#         }
#       }
#
#       custom_rules = {
#         "block-scanner-net" = {
#           name     = "block-scanner-net"
#           priority = 100
#           action   = "Block"
#
#           match_conditions = {
#             "source" = {
#               operator     = "IPMatch"
#               match_values = ["203.0.113.0/24"]
#
#               match_variables = {
#                 "remote-addr" = {
#                   variable_name = "RemoteAddr"
#                 }
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

inputs = {
  policies = {}
}
