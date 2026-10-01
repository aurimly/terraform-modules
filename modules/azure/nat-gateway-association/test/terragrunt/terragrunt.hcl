terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   subnet_nat_gateway_associations = {
#     "workload" = {
#       subnet_id      = "/subscriptions/<subscription-id>/resourceGroups/rg-platform-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform-prod/subnets/snet-workload"
#       nat_gateway_id = "/subscriptions/<subscription-id>/resourceGroups/rg-platform-prod/providers/Microsoft.Network/natGateways/ngw-platform-prod"
#     }
#   }
# }

inputs = {
  subnet_nat_gateway_associations = {
    "example" = {
      subnet_id      = "/subscriptions/<subscription-id>/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example/subnets/snet-example"
      nat_gateway_id = "/subscriptions/<subscription-id>/resourceGroups/rg-example/providers/Microsoft.Network/natGateways/ngw-example"
    }
  }
}
