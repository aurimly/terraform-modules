terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   network_interfaces = {
#     "workload" = {
#       name                = "nic-workload-prod"
#       resource_group_name = "rg-platform-prod"
#       location            = "westeurope"
#       ip_configurations = {
#         "primary" = {
#           subnet_id                     = dependency.subnet.outputs.subnet_ids["workload"]
#           private_ip_address_allocation = "Dynamic"
#           primary                       = true
#           public_ip_address_id          = dependency.pip.outputs.public_ip_ids["ingress"]
#         }
#       }
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  network_interfaces = {
    "example" = {
      name                = "nic-example"
      resource_group_name = "rg-example"
      location            = "westeurope"
      ip_configurations = {
        "primary" = {
          subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example/subnets/snet-example"
          private_ip_address_allocation = "Dynamic"
          primary                       = true
        }
      }
    }
  }
}
