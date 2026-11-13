terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   subnet_route_table_associations = {
#     "workload" = {
#       subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform-prod/subnets/snet-workload"
#       route_table_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod/providers/Microsoft.Network/routeTables/rt-hub-egress"
#     }
#   }
# }

inputs = {
  subnet_route_table_associations = {
    "workload" = {
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example/subnets/snet-workload"
      route_table_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/routeTables/rt-hub-egress"
    }
  }
}
