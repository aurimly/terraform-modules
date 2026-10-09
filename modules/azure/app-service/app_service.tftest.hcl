mock_provider "azurerm" {
  mock_resource "azurerm_service_plan" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-apps-prod/providers/Microsoft.Web/serverFarms/asp-platform-mock"
    }
  }

  mock_resource "azurerm_linux_web_app" {
    defaults = {
      id                            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-apps-prod/providers/Microsoft.Web/sites/web-api-mock"
      default_hostname              = "web-api-mock.azurewebsites.net"
      outbound_ip_address_list      = ["198.51.100.10"]
      custom_domain_verification_id = "customdomainverificationid-mock"

    }
  }

  mock_resource "azurerm_windows_web_app" {
    defaults = {
      id                            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-apps-prod/providers/Microsoft.Web/sites/app-win-mock"
      outbound_ip_address_list      = ["198.51.100.10"]
      custom_domain_verification_id = "customdomainverificationid-mock"
      default_hostname              = "app-win-mock.azurewebsites.net"

    }
  }
}

run "full_app_service" {
  command = plan

  variables {
    service_plans = {
      "linux-plans" = {
        name                   = "asp-linux-prod"
        resource_group_name    = "rg-apps-prod"
        location               = "westeurope"
        os_type                = "Linux"
        sku_name               = "P1v3"
        worker_count           = 2
        zone_balancing_enabled = true
      }

      "win-plans" = {
        name                = "asp-win-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Windows"
        sku_name            = "B2"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "linux-plans"

        app_settings = {
          WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
        }

        connection_strings = {
          "primary-db" = {
            type  = "PostgreSQL"
            value = "Server=203.0.113.10;Database=orders;"
          }
        }

        identity = {
          type         = "SystemAssigned"
          identity_ids = []
        }

        virtual_network_subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-apps/subnets/apps"

        ftp_publish_basic_authentication_enabled       = false
        webdeploy_publish_basic_authentication_enabled = false

        site_config = {
          health_check_path                 = "/healthz"
          health_check_eviction_time_in_min = 5

          application_stack = {
            node_version = "22-lts"
          }

          cors = {
            allowed_origins = ["https://portal.example.com"]
          }

          ftps_state          = "Disabled"
          minimum_tls_version = "1.2"
          ip_restriction = {
            "vnet-only" = {
              name                      = "vnet-only"
              action                    = "Deny"
              virtual_network_subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-apps/subnets/apps"
              description               = "block everything except the apps subnet"
            }
          }
          ip_restriction_default_action = "Deny"
        }

        tags = {
          env = "prod"
        }
      }
    }

    windows_web_apps = {
      "admin" = {
        name                = "web-admin-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "win-plans"

        site_config = {
          application_stack = {
            current_stack  = "dotnetcore"
            dotnet_version = "v8.0"
          }
          ftps_state = "AllAllowed"
        }
      }
    }

    linux_web_app_slots = {
      "api-staging" = {
        app_key = "api"
        name    = "staging"

        site_config = {
          auto_swap_slot_name = "production"

          application_stack = {
            node_version = "22-lts"
          }
        }
      }
    }

    windows_web_app_slots = {
      "admin-staging" = {
        app_key     = "admin"
        name        = "staging"
        site_config = {}
      }
    }
  }
}

run "rejects_dot_in_app_key" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api.a" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"
        site_config         = {}
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_windows_app_on_linux_plan" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    windows_web_apps = {
      "admin" = {
        name                = "web-admin-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"
        site_config         = {}
      }
    }
  }

  expect_failures = [var.windows_web_apps]
}

run "rejects_region_mismatch_with_plan" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "eastus"
        service_plan_key    = "platform"
        site_config         = {}
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_always_on_on_free_plan" {
  command = plan

  variables {
    service_plans = {
      "free" = {
        name                = "asp-free-ng"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "F1"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "free"

        site_config = {
          always_on = true
        }
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_bad_app_name" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "not_valid_name"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"
        site_config         = {}
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_app_without_plan" {
  command = plan

  variables {
    service_plans = {}

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        site_config         = {}
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_ip_restriction_with_two_sources" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"

        site_config = {
          ip_restriction = {
            "double" = {
              name                      = "vnet-and-ip"
              ip_address                = "203.0.113.10"
              virtual_network_subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-apps/subnets/apps"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_health_eviction_without_path" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"

        site_config = {
          health_check_eviction_time_in_min = 5
        }
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_linux_stack_with_two_languages" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"

        site_config = {
          application_stack = {
            dotnet_version = "8.0"
            python_version = "3.12"
          }
        }
      }
    }
  }

  expect_failures = [var.linux_web_apps]
}

run "rejects_windows_stack_without_current_stack" {
  command = plan

  variables {
    service_plans = {
      "win" = {
        name                = "asp-win-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Windows"
        sku_name            = "B2"
      }
    }

    windows_web_apps = {
      "admin" = {
        name                = "web-admin-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "win"

        site_config = {
          application_stack = {
            dotnet_version = "v8.0"
          }
        }
      }
    }
  }

  expect_failures = [var.windows_web_apps]
}

run "rejects_slot_on_unknown_app" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                = "asp-platform-prod"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "P1v3"
      }
    }

    linux_web_apps = {
      "api" = {
        name                = "web-api-prod-euw"
        resource_group_name = "rg-apps-prod"
        location            = "westeurope"
        service_plan_key    = "platform"
        site_config         = {}
      }
    }

    linux_web_app_slots = {
      "other-staging" = {
        app_key     = "other"
        name        = "staging"
        site_config = {}
      }
    }
  }

  expect_failures = [var.linux_web_app_slots]
}

run "rejects_plan_with_autoscale_and_fixed_workers" {
  command = plan

  variables {
    service_plans = {
      "platform" = {
        name                            = "asp-platform-prod"
        resource_group_name             = "rg-apps-prod"
        location                        = "westeurope"
        os_type                         = "Linux"
        sku_name                        = "P1v3"
        worker_count                    = 2
        premium_plan_auto_scale_enabled = true
      }
    }
  }

  expect_failures = [var.service_plans]
}
