terraform {
  source = "../../"
}

# Example inputs (commented). To plan against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   postgresql_servers = {
#     "orders-primary" = {
#       name                = "psql-orders-prod-01"
#       resource_group_name = "rg-data-prod"
#       location            = "westeurope"
#       sku_name            = "GP_Standard_D2ds_v4"
#       version             = "17"
#       administrator_login = "orders_admin"
#       administrator_password_wo         = "Ex4mple!Pw"
#       administrator_password_wo_version = 1
#       backup_retention_days     = 14
#       zone                      = "1"
#       storage_mb                = 65536
#       storage_tier              = "P30"
#       auto_grow_enabled         = true
#       databases = {
#         "orders" = {
#           name = "orders"
#         }
#       }
#       firewall_rules = {
#         "office" = {
#           name             = "office"
#           start_ip_address = "203.0.113.10"
#           end_ip_address   = "203.0.113.30"
#         }
#       }
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  postgresql_servers = {}
}
