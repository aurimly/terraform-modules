terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   route_tables = {
#     "hub-egress" = {
#       name                          = "rt-hub-egress"
#       resource_group_name           = "rg-platform-prod"
#       location                      = "westeurope"
#       bgp_route_propagation_enabled = false
#     }
#   }
# }

inputs = {
  route_tables = {
    "hub-egress" = {
      name                          = "rt-hub-egress"
      resource_group_name           = "rg-example"
      location                      = "westeurope"
      bgp_route_propagation_enabled = false
      routes = {
        "firewall" = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.10.1.4"
        }
        "spoke-summary" = {
          address_prefix         = "10.20.0.0/16"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.10.1.4"
        }
      }
    }
    "spoke-internet" = {
      name                = "rt-spoke-internet"
      resource_group_name = "rg-example"
      location            = "westeurope"
      routes = {
        "all" = {
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "Internet"
        }
      }
    }
  }
}
