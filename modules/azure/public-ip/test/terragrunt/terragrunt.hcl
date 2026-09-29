terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   public_ips = {
#     "ingress" = {
#       name                = "pip-ingress-prod"
#       resource_group_name = "rg-platform-prod"
#       location            = "westeurope"
#       allocation_method   = "Static"
#       sku                 = "Standard"
#       availability_zone   = "1"
#       domain_name_label   = "ingress-example"
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  public_ips = {
    "example" = {
      name                = "pip-example"
      resource_group_name = "rg-example"
      location            = "westeurope"
      allocation_method   = "Static"
      tags = {
        env = "example"
      }
    }
  }
}
