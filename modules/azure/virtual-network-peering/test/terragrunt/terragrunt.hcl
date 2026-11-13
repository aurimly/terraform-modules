terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   virtual_network_peerings = {
#     "hub-to-spoke" = {
#       name                      = "peer-hub-to-spoke"
#       resource_group_name       = "rg-platform-prod"
#       virtual_network_name      = "vnet-platform-prod"
#       remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
#     }
#   }
# }

# The two entries form one bidirectional pair. Azure serializes peering CRUD on
# the same pair — see the README's concurrency note before adding directions by
# hand alongside an apply.
inputs = {
  virtual_network_peerings = {
    "hub-to-spoke" = {
      name                      = "peer-hub-to-spoke"
      resource_group_name       = "rg-example"
      virtual_network_name      = "vnet-hub"
      remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
      allow_forwarded_traffic   = true
      allow_gateway_transit     = true
    }
    "spoke-to-hub" = {
      name                      = "peer-spoke-to-hub"
      resource_group_name       = "rg-example"
      virtual_network_name      = "vnet-spoke"
      remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-hub"
      use_remote_gateways       = true
      triggers = {
        remote_address_space = "10.10.0.0/16,fd00::/8"
      }
    }
  }
}
