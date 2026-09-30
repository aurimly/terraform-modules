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
#       zone_name           = "example.com"
#       resource_group_name = "rg-dns-prod"
#       records = {
#         "apex-a" = {
#           name    = "@"
#           type    = "A"
#           ttl     = 300
#           records = ["203.0.113.10"]
#         }
#       }
#     }
#     "private" = {
#       private_dns_zone_id = "/subscriptions/12345678-1234-5678-9012-123456789012/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/internal.example.com"
#       records = {
#         "api-a" = {
#           name    = "api"
#           type    = "A"
#           ttl     = 300
#           records = ["10.20.0.10"]
#         }
#       }
#     }
#   }
# }

inputs = {
  zones = {}
}
