terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   managed_identities = {
#     "workload" = {
#       name                = "id-workload-prod"
#       resource_group_name = dependency.rg.outputs.resource_group_names["platform"]
#       location            = "westeurope"
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  managed_identities = {
    "example" = {
      name                = "id-example"
      resource_group_name = "rg-example"
      location            = "westeurope"
      tags = {
        env = "example"
      }
    }
  }
}
