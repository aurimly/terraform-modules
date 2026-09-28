terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   resource_groups = {
#     "platform-prod" = {
#       name     = "rg-platform-prod"
#       location = "westeurope"
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  resource_groups = {
    "example" = {
      name     = "rg-example"
      location = "westeurope"
      tags = {
        env = "example"
      }
    }
  }
}
