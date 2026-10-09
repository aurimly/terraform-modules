terraform {
  source = "../../"
}

# Example inputs (commented). To plan against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with an empty map needs no
# Azure creds — nothing here calls the API.
#
# inputs = {
#   service_plans = {
#     "platform" = {
#       name                   = "asp-platform-prod"
#       resource_group_name    = "rg-apps-prod"
#       location               = "westeurope"
#       os_type                = "Linux"
#       sku_name               = "P1v3"
#       worker_count           = 2
#       zone_balancing_enabled = true
#     }
#   }
#
#   linux_web_apps = {
#     "api" = {
#       name                = "web-api-prod-euw"
#       resource_group_name = "rg-apps-prod"
#       location            = "westeurope"
#       service_plan_key    = "platform"
#
#       ftp_publish_basic_authentication_enabled       = false
#       webdeploy_publish_basic_authentication_enabled = false
#
#       site_config = {
#         health_check_path                 = "/healthz"
#         health_check_eviction_time_in_min = 5
#         application_stack = {
#           node_version = "22-lts"
#         }
#       }
#     }
#   }
#
#   linux_web_app_slots = {
#     "api-staging" = {
#       app_key = "api"
#       name    = "staging"
#       site_config = {
#         auto_swap_slot_name = "production"
#       }
#     }
#   }
# }

inputs = {
  service_plans = {}
}
