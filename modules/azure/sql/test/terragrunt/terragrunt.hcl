terraform {
  source = "../../"
}

# Example inputs (commented). To plan against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   sql_servers = {
#     "orders-primary" = {
#       name                = "sql-orders-prod-01"
#       resource_group_name = "rg-data-prod"
#       location            = "westeurope"
#       administrator_login = "orders_admin"
#       administrator_login_password_wo         = "Ex4mple!Pw"
#       administrator_login_password_wo_version = 1
#       azuread_administrator = {
#         login_username              = "sql-admins"
#         object_id                   = "11111111-2222-3333-4444-555555555555"
#         azuread_authentication_only = false
#       }
#       minimum_tls_version = "1.2"
#
#       elastic_pools = {
#         "main" = {
#           name = "pool-orders-prod"
#           sku = {
#             name     = "GP_Gen5"
#             tier     = "GeneralPurpose"
#             capacity = 4
#             family   = "Gen5"
#           }
#           max_size_gb = 1024
#           per_database_settings = {
#             min_capacity = 0.5
#             max_capacity = 4
#           }
#           tags = {
#             env = "prod"
#           }
#         }
#       }
#
#       databases = {
#         "orders" = {
#           name       = "orders"
#           collation  = "SQL_Latin1_General_CP1_CI_AS"
#           sku_name   = "GP_Gen5_2"
#           max_size_gb = 128
#           storage_account_type = "GeoZone"
#           short_term_retention_policy = {
#             retention_days           = 21
#             backup_interval_in_hours = 12
#           }
#           long_term_retention_policy = {
#             weekly_retention  = "P1W"
#             monthly_retention = "P1M"
#             yearly_retention  = "P1Y"
#             week_of_year      = 1
#           }
#         }
#         "pooled" = {
#           name            = "orders-pooled"
#           sku_name        = "ElasticPool"
#           elastic_pool_key = "main"
#         }
#       }
#
#       firewall_rules = {
#         "office" = {
#           name             = "office"
#           start_ip_address = "203.0.113.10"
#           end_ip_address   = "203.0.113.30"
#         }
#       }
#
#       failover_groups = {
#         "main" = {
#           name              = "fog-orders-prod"
#           partner_server_id = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Sql/servers/<partner-server>"
#           database_keys     = ["orders"]
#           read_write_endpoint_failover_policy = {
#             mode          = "Automatic"
#             grace_minutes = 60
#           }
#         }
#       }
#
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  sql_servers = {}
}
