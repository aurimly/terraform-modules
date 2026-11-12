terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with empty maps
# needs no creds.
#
# inputs = {
#   organization = {
#     aws_service_access_principals = ["cloudtrail.amazonaws.com"]
#     enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
#     feature_set                   = "ALL"
#   }
#   ous = {
#     "workloads" = {
#       name = "workloads"
#     }
#     "sandbox" = {
#       parent = "workloads"
#       name   = "sandbox"
#     }
#   }
#   policies = {
#     "deny-region" = {
#       name    = "deny-region"
#       content = jsonencode({ Version = "2012-10-17", Statement = [] })
#     }
#   }
#   policy_attachments = {
#     "deny-region-root" = {
#       policy_key   = "deny-region"
#       target_root  = true
#     }
#   }
#   delegated_administrators = {
#     "security" = {
#       account_id        = "123456789012"
#       service_principal = "guardduty.amazonaws.com"
#     }
#   }
# }

inputs = {
  ous                      = {}
  policies                 = {}
  policy_attachments       = {}
  delegated_administrators = {}
}
