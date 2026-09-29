terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   storage_accounts = {
#     "data" = {
#       name                     = "stexampledata01"
#       resource_group_name      = dependency.rg.outputs.resource_group_names["platform"]
#       location                 = "westeurope"
#       account_tier             = "Standard"
#       account_replication_type = "LRS"
#       account_kind             = "StorageV2"
#       access_tier              = "Hot"
#       network_rules = {
#         default_action             = "Deny"
#         bypass                     = ["AzureServices"]
#         ip_rules                   = ["203.0.113.0/24"]
#         virtual_network_subnet_ids = [dependency.subnet.outputs.subnet_ids["workload"]]
#       }
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  storage_accounts = {
    "example" = {
      name                     = "stexampleacct01"
      resource_group_name      = "rg-example"
      location                 = "westeurope"
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind             = "StorageV2"
      access_tier              = "Hot"
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["203.0.113.0/24"]
        virtual_network_subnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example/subnets/snet-example"]
      }
      tags = {
        env = "example"
      }
    }
  }
}
# NEGATIVE TEST - remove after
