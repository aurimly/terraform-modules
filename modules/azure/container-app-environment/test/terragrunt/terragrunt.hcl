terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   container_app_environments = {
#     "platform" = {
#       name                = "cae-eu-prod-01"
#       resource_group_name = dependency.rg.outputs.resource_group_names["platform"]
#       location            = "westeurope"
#
#       logs_destination           = "log-analytics"
#       log_analytics_workspace_id = dependency.log.outputs.workspace_ids["platform"]
#
#       workload_profile = {
#         "d4" = {
#           name                  = "D4"
#           workload_profile_type = "D4"
#           maximum_count         = 10
#           minimum_count         = 2
#         }
#       }
#
#       infrastructure_subnet_id           = dependency.subnet.outputs.subnet_ids["cae"]
#       internal_load_balancer_enabled     = true
#       zone_redundancy_enabled            = true
#       tags = {
#         env = "prod"
#       }
#     }
#   }
# }

inputs = {
  container_app_environments = {
    "example" = {
      name                = "cae-example"
      resource_group_name = "rg-rg-example"
      location            = "westeurope"
      tags = {
        env = "example"
      }
    }
  }
}
