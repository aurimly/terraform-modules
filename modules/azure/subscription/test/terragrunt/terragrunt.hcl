terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the sample inputs needs
# no Azure creds — nothing here calls the API.
#
# inputs = {
#   subscriptions = {
#     "platform-prod" = {
#       subscription_name = "Platform Production"
#       billing_scope_id  = "/providers/Microsoft.Billing/billingAccounts/1234567890/enrollmentAccounts/0123456"
#       alias             = "platform-prod"
#       tags = {
#         env = "prod"
#       }
#     }
#     "legacy-sub" = {
#       subscription_name = "Legacy Example"
#       subscription_id   = "12345678-1234-5678-9012-123456789012"
#     }
#   }
# }

inputs = {
  subscriptions = {
    "example" = {
      subscription_name = "Example Subscription"
      billing_scope_id  = "/providers/Microsoft.Billing/billingAccounts/1234567890/enrollmentAccounts/0123456"
      alias             = "example-sub"
      tags = {
        env = "test"
      }
    }
  }
}
