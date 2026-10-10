mock_provider "azurerm" {
  mock_resource "azurerm_container_registry" {
    defaults = {
      id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.ContainerRegistry/registries/ordersprodregistry01"
      login_server = "ordersprodregistry01.azurecr.io"
    }
  }
  mock_resource "azurerm_container_registry_webhook" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.ContainerRegistry/registries/ordersprodregistry01/webHooks/deployhook"
    }
  }
  mock_resource "azurerm_container_registry_scope_map" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.ContainerRegistry/registries/ordersprodregistry01/scopeMaps/cipull"
    }
  }
  mock_resource "azurerm_container_registry_token" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.ContainerRegistry/registries/ordersprodregistry01/tokens/civ1pull"
    }
  }
  mock_resource "azurerm_container_registry_token_password" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-store-prod/providers/Microsoft.ContainerRegistry/registries/ordersprodregistry01/tokens/civ1pull/passwords/password"
    }
  }
}

run "full_registry" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        sku                 = "Premium"

        zone_redundancy_enabled   = true
        retention_policy_in_days  = 30
        quarantine_policy_enabled = true
        role_assignment_mode      = "AbacRepositoryPermissions"

        georeplications = {
          "us" = {
            location                = "eastus"
            zone_redundancy_enabled = true
          }
          "eu2" = {
            location = "northeurope"
          }
        }

        network_rule_set = {
          default_action = "Deny"
          ip_rule = {
            "office" = {
              ip_range = "203.0.113.0/24"
            }
          }
        }

        webhooks = {
          "deploy" = {
            name        = "deployhook"
            service_uri = "https://webhook.example.com/deploy"
            actions     = ["push", "chart_push"]
          }
        }

        scope_maps = {
          "ci-pull" = {
            name    = "cipull"
            actions = ["repositories/app/content/read"]
          }
        }

        tokens = {
          "civ1pull" = {
            name             = "civ1pull"
            scope_map_key    = "ci-pull"
            password1_expiry = "2027-01-02T03:04:05Z"
          }
          "legacypull" = {
            name          = "legacypull"
            scope_map_key = "ci-pull"
            enabled       = false
          }
        }

        tags = {
          env = "prod"
        }
      }
    }
  }
}

run "rejects_hyphen_in_name" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "orders-prod-registry"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_georeplication_on_basic" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        sku                 = "Basic"
        georeplications = {
          "us" = {
            location = "eastus"
          }
        }
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_georeplication_of_own_location" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        sku                 = "Premium"
        georeplications = {
          "eu" = {
            location = "westeurope"
          }
        }
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_unknown_webhook_action" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        webhooks = {
          "deploy" = {
            name        = "deployhook"
            service_uri = "https://webhook.example.com/deploy"
            actions     = ["punch"]
          }
        }
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_token_missing_scope_map" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        tokens = {
          "civ1pull" = {
            name          = "civ1pull"
            scope_map_key = "does-not-exist"
          }
        }
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_export_lock_with_public_access" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                          = "ordersprodregistry01"
        resource_group_name           = "rg-store-prod"
        location                      = "westeurope"
        export_policy_enabled         = false
        public_network_access_enabled = true
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_non_allow_ip_action" {
  command = plan

  variables {
    container_registries = {
      "primary-eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
        sku                 = "Premium"
        network_rule_set = {
          default_action = "Deny"
          ip_rule = {
            "office" = {
              action   = "Deny"
              ip_range = "203.0.113.0/24"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_dotted_key" {
  command = plan

  variables {
    container_registries = {
      "primary.eu" = {
        name                = "ordersprodregistry01"
        resource_group_name = "rg-store-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.container_registries]
}
