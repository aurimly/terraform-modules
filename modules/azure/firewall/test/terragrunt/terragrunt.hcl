terraform {
  source = "../../"
}

# Example inputs (commented). To plan against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   public_ips = {
#     "egress" = {
#       name                = "pip-fw-egress-prod"
#       resource_group_name = "rg-network-prod"
#       location            = "westeurope"
#       availability_zone   = "1"
#     }
#   }
#
#   firewall_policies = {
#     "egress" = {
#       name                = "fwp-egress-prod"
#       resource_group_name = "rg-network-prod"
#       location            = "westeurope"
#     }
#   }
#
#   firewall_policy_rule_collection_groups = {
#     "egress-base" = {
#       firewall_policy_key = "egress"
#       name                = "rgp-egress"
#       priority            = 100
#
#       network_rule_collections = {
#         "allow-internal" = {
#           name     = "nrc-allow-internal"
#           priority = 100
#           action   = "Allow"
#
#           rules = {
#             "internal-dns" = {
#               name                = "nr-allow-dns"
#               protocols           = ["UDP"]
#               destination_address = "10.0.0.10"
#               destination_ports   = ["53"]
#               source_addresses    = ["192.168.1.0/24"]
#             }
#           }
#         }
#       }
#     }
#   }
#
#   firewalls = {
#     "egress" = {
#       name                = "fw-platform-prod"
#       resource_group_name = "rg-network-prod"
#       location            = "westeurope"
#       sku_name            = "AZFW_VNet"
#       sku_tier            = "Premium"
#       firewall_policy_key = "egress"
#       zones               = ["1", "2", "3"]
#
#       ip_configurations = {
#         "primary" = {
#           name          = "pip-fw-primary"
#           subnet_id     = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/AzureFirewallSubnet"
#           public_ip_key = "egress"
#         }
#       }
#     }
#   }
# }

inputs = {
  firewalls = {}
}
