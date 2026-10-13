mock_provider "azurerm" {
  mock_resource "azurerm_container_app_environment" {
    defaults = {
      id                            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-mock"
      default_domain                = "cae-eu-mock.northeurope.azurecontainerapps.io"
      static_ip_address             = "10.20.0.4"
      custom_domain_verification_id = "mock"
    }
  }
}

run "full_environments" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                = "cae-eu-prod-01"
        resource_group_name = "rg-platform-prod"
        location            = "northeurope"

        logs_destination           = "log-analytics"
        log_analytics_workspace_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-terraform-state/providers/Microsoft.OperationalInsights/workspaces/log-platform-prod"

        identity = {
          type         = "UserAssigned"
          identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cae"]
        }

        infrastructure_subnet_id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/snet-cae"
        infrastructure_resource_group_name = "rg-managed-cae"
        zone_redundancy_enabled            = true
        public_network_access              = "Disabled"

        workload_profile = {
          "d4" = {
            name                  = "D4"
            workload_profile_type = "D4"
            maximum_count         = 10
            minimum_count         = 2
          }
        }

        tags = {
          env = "prod"
        }
      }
      "shared" = {
        name                = "cae-shared-prod-01"
        resource_group_name = "rg-platform-prod"
        location            = "northeurope"
        mutual_tls_enabled  = true
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                = "cae-eu-mock--"
        resource_group_name = "rg-platform-prod"
        location            = "northeurope"
      }
    }
  }

  expect_failures = [var.container_app_environments]
}

run "rejects_workspace_without_log_analytics_destination" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                = "cae-eu-prod-01"
        resource_group_name = "rg-platform-prod"
        location            = "northeurope"

        logs_destination           = "azure-monitor"
        log_analytics_workspace_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-terraform-state/providers/Microsoft.OperationalInsights/workspaces/log-platform-prod"
      }
    }
  }

  expect_failures = [var.container_app_environments]
}

run "rejects_ilb_without_subnet" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                           = "cae-eu-prod-01"
        resource_group_name            = "rg-platform-prod"
        location                       = "northeurope"
        internal_load_balancer_enabled = true
      }
    }
  }

  expect_failures = [var.container_app_environments]
}

run "rejects_public_access_with_ilb" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                           = "cae-eu-prod-01"
        resource_group_name            = "rg-platform-prod"
        location                       = "northeurope"
        infrastructure_subnet_id       = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-platform/subnets/snet-cae"
        internal_load_balancer_enabled = true
        public_network_access          = "Enabled"
      }
    }
  }

  expect_failures = [var.container_app_environments]
}

run "rejects_consumption_profile_counts" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                = "cae-eu-prod-01"
        resource_group_name = "rg-platform-prod"
        location            = "northeurope"

        workload_profile = {
          "consumption" = {
            name                  = "Consumption"
            workload_profile_type = "Consumption"
            minimum_count         = 2
            maximum_count         = 10
          }
        }
      }
    }
  }

  expect_failures = [var.container_app_environments]
}

run "rejects_infra_resource_group_without_profile" {
  command = plan

  variables {
    container_app_environments = {
      "platform" = {
        name                = "cae-eu-prod-01"
        resource_group_name = "rg-platform-prod"
        location            = "northeurope"

        infrastructure_resource_group_name = "rg-managed-cae"
      }
    }
  }

  expect_failures = [var.container_app_environments]
}
