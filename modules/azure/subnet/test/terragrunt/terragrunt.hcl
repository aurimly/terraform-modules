terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   subnets = {
#     "workload" = {
#       name                 = "snet-workload"
#       resource_group_name  = "rg-platform-prod"
#       virtual_network_name = "vnet-platform-prod"
#       address_prefixes = [
#         "10.0.1.0/24",
#       ]
#     }
#   }
# }

inputs = {
  subnets = {
    "example" = {
      name                 = "snet-example"
      resource_group_name  = "rg-example"
      virtual_network_name = "vnet-example"
      address_prefixes = [
        "10.0.1.0/24",
      ]
      delegations = {
        "container-instances" = {
          service_delegation_name = "Microsoft.ContainerInstance/containerGroups"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/action",
          ]
        }
      }
      service_endpoints = {
        "storage" = {
          service = "Microsoft.Storage"
        }
      }
    }
  }
}
