terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   zones = {
#     "public" = {
#       name                = "example.com"
#       resource_group_name = "rg-dns-prod"
#       soa_record = {
#         email       = "hostmaster.example.com"
#         minimum_ttl = 60
#       }
#     }
#     "private-endpoints" = {
#       name                = "privatelink.postgres.database.azure.com"
#       resource_group_name = "rg-dns-prod"
#       private             = true
#       virtual_network_links = {
#         "hub" = {
#           name               = "link-hub-vnet"
#           virtual_network_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-hub"
#         }
#       }
#     }
#   }
# }

inputs = {
  zones = {}
}
