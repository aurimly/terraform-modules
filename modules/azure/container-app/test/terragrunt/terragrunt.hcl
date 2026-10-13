terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds; the provider config still needs
# an ARM_SUBSCRIPTION_ID). terragrunt validate with the placeholder inputs
# needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   container_apps = {
#     "api" = {
#       name                         = "api-prod"
#       resource_group_name          = dependency.rg.outputs.resource_group_names["platform"]
#       container_app_environment_id = dependency.cae.outputs.environment_ids["platform"]
#       revision_mode                = "Single"
#
#       secret = {
#         "cr-password" = {
#           name  = "cr-password"
#           value = "example-placeholder"
#         }
#       }
#
#       registry = {
#         "primary" = {
#           server               = "crplatformprod.azurecr.io"
#           username             = "cruser"
#           password_secret_name = "cr-password"
#         }
#       }
#
#       template = {
#         container = {
#           "api" = {
#             name   = "api"
#             image  = "crplatformprod.azurecr.io/api:v1.2.3"
#             cpu    = 0.5
#             memory = "1.0Gi"
#           }
#         }
#
#         max_replicas = 20
#       }
#
#       ingress = {
#         target_port      = 3000
#         external_enabled = true
#
#         traffic_weight = {
#           "latest" = {
#             latest_revision = true
#             percentage      = 100
#           }
#         }
#       }
#
#       tags = {
#         app = "api"
#       }
#     }
#   }
# }

inputs = {
  container_apps = {
    "example" = {
      name                         = "app-example"
      resource_group_name          = "rg-example"
      container_app_environment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.App/managedEnvironments/cae-example"
      revision_mode                = "Single"
      template = {
        container = {
          "app" = {
            name   = "app"
            image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld"
            cpu    = 0.5
            memory = "1.0Gi"
          }
        }
      }
      ingress = {
        target_port = 3000
        traffic_weight = {
          "latest" = {
            latest_revision = true
            percentage      = 100
          }
        }
      }
      tags = {
        env = "example"
      }
    }
  }
}
