terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   key_vaults = {
#     "platform" = {
#       name                = "kv-platform-prod-01"
#       resource_group_name = "rg-platform-prod"
#       location            = "westeurope"
#       tenant_id           = "11111111-2222-3333-4444-555555555555"
#       network_acls = {
#         default_action = "Deny"
#         bypass         = "AzureServices"
#         ip_rules       = ["203.0.113.0/24"]
#       }
#       keys = {
#         "cmk" = {
#           name     = "storage-cmk"
#           key_type = "RSA-HSM"
#           key_size = 3072
#           key_opts = ["unwrapKey", "wrapKey"]
#           rotation_policy = {
#             expire_after         = "P90D"
#             notify_before_expiry = "P30D"
#           }
#         }
#       }
#       secrets = {
#         "sql-password" = {
#           name             = "sql-admin-password"
#           value_wo         = "example-password"
#           value_wo_version = 1
#         }
#       }
#       certificates = {
#         "web-tls" = {
#           name = "web-tls"
#           certificate_policy = {
#             issuer_parameters = {
#               name = "Self"
#             }
#             key_properties = {
#               exportable = true
#               key_type   = "RSA"
#               key_size   = 2048
#               reuse_key  = true
#             }
#             lifetime_action = [
#               {
#                 action  = { action_type = "AutoRenew" }
#                 trigger = { days_before_expiry = 30 }
#               },
#             ]
#             secret_properties = {
#               content_type = "application/x-pkcs12"
#             }
#             x509_certificate_properties = {
#               subject            = "CN=app.example.internal"
#               validity_in_months = 12
#               key_usage          = ["digitalSignature", "keyEncipherment"]
#             }
#           }
#         }
#       }
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  key_vaults = {}
}
