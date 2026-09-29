terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   virtual_networks = {
#     "platform-prod" = {
#       name                = "vnet-platform-prod"
#       resource_group_name = "rg-platform-prod"
#       location            = "westeurope"
#       address_space = [
#         "10.0.0.0/16",
#       ]
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  virtual_networks = {
    "example" = {
      name                = "vnet-example"
      resource_group_name = "rg-example"
      location            = "westeurope"
      address_space = [
        "10.0.0.0/16",
      ]
      tags = {
        env = "example"
      }
    }
  }
}
