terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   network_security_groups = {
#     "workload" = {
#       name                = "nsg-workload"
#       resource_group_name = "rg-platform-prod"
#       location            = "westeurope"
#       security_rules = {
#         "allow-https-in" = {
#           name                       = "AllowHTTPSIn"
#           priority                   = 100
#           direction                  = "Inbound"
#           access                     = "Allow"
#           protocol                   = "Tcp"
#           source_port_range          = "*"
#           destination_port_range     = "443"
#           source_address_prefix      = "Internet"
#           destination_address_prefix = "VirtualNetwork"
#         }
#       }
#     }
#   }
# }

inputs = {
  network_security_groups = {
    "example" = {
      name                = "nsg-example"
      resource_group_name = "rg-example"
      location            = "westeurope"
      security_rules = {
        "allow-https-in" = {
          name                       = "AllowHTTPSIn"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "VirtualNetwork"
        }
        "allow-all-out" = {
          name                       = "AllowAllOut"
          priority                   = 4090
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "Internet"
        }
      }
    }
  }
}
