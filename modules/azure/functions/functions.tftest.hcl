mock_provider "azurerm" {
  mock_resource "azurerm_service_plan" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-func-prod/providers/Microsoft.Web/serverFarms/asp-func-prod"
    }
  }
  mock_resource "azurerm_linux_function_app" {
    defaults = {
      id                            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-func-prod/providers/Microsoft.Web/sites/func-notify-prod"
      kind                          = "functionapp,linux,container"
      default_hostname              = "func-notify-prod.azurewebsites.net"
      outbound_ip_address_list      = ["52.0.0.1"]
      custom_domain_verification_id = "mock"
    }
  }
  mock_resource "azurerm_windows_function_app" {
    defaults = {
      id                            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-func-prod/providers/Microsoft.Web/sites/func-batch-prod"
      kind                          = "functionapp"
      default_hostname              = "func-batch-prod.azurewebsites.net"
      outbound_ip_address_list      = ["52.0.0.2"]
      custom_domain_verification_id = "mock"
    }
  }
  mock_data "azurerm_function_app_host_keys" {
    defaults = {
      default_function_key = "mock-function-key"
      primary_key          = "mock-primary-key"
    }
  }
}

run "linux_and_windows_apps" {
  command = plan

  variables {
    service_plans = {
      "plan-linux" = {
        name                = "asp-func-prod"
        resource_group_name = "rg-func-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "EP1"
      }
      "plan-windows" = {
        name                = "asp-func-win-prod"
        resource_group_name = "rg-func-prod"
        location            = "westeurope"
        os_type             = "Windows"
        sku_name            = "P1v3"
      }
    }

    linux_function_apps = {
      "notify" = {
        name                          = "func-notify-prod"
        resource_group_name           = "rg-func-prod"
        location                      = "westeurope"
        service_plan_key              = "plan-linux"
        storage_account_name          = "stfuncprod"
        storage_uses_managed_identity = true
        identity = {
          type = "SystemAssigned"
        }
        site_config = {
          application_stack = {
            dotnet_version = "8.0"
          }
        }
      }
    }

    windows_function_apps = {
      "batch" = {
        name                       = "func-batch-prod"
        resource_group_name        = "rg-func-prod"
        location                   = "westeurope"
        service_plan_key           = "plan-windows"
        storage_account_name       = "stfuncprod"
        storage_account_access_key = "mock-access-key"
        site_config = {
          application_stack = {
            dotnet_version = "v8.0"
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_linux_function_app.linux_function_app) == 1
    error_message = "one linux function app expected"
  }
  assert {
    condition     = length(azurerm_windows_function_app.windows_function_app) == 1
    error_message = "one windows function app expected"
  }
  assert {
    condition     = length(azurerm_service_plan.service_plan) == 2
    error_message = "both plans instantiated"
  }
  assert {
    condition     = length(data.azurerm_function_app_host_keys.host_keys) == 2
    error_message = "host keys read for both apps"
  }
}

run "outputs_keyed_with_family_prefix" {
  command = plan

  variables {
    service_plans = {
      "plan-linux" = {
        name                = "asp-func-prod"
        resource_group_name = "rg-func-prod"
        location            = "westeurope"
        os_type             = "Linux"
        sku_name            = "EP1"
      }
    }

    linux_function_apps = {
      "notify" = {
        name                          = "func-notify-prod"
        resource_group_name           = "rg-func-prod"
        location                      = "westeurope"
        service_plan_key              = "plan-linux"
        storage_account_name          = "stfuncprod"
        storage_uses_managed_identity = true
        identity = {
          type = "SystemAssigned"
        }
        site_config = {
          application_stack = {
            node_version = "20"
          }
        }
      }
    }
  }

  assert {
    condition     = output.linux_function_app_names["notify"] == "func-notify-prod"
    error_message = "linux app names keyed by map key"
  }
  assert {
    condition     = output.linux_function_app_default_hostnames["notify"] == "func-notify-prod.azurewebsites.net"
    error_message = "default hostname output"
  }
  assert {
    condition     = output.linux_function_app_identity_principal_ids["notify"] != null
    error_message = "identity principal id surfaced for system-assigned identity (mocked non-empty)"
  }
  assert {
    condition     = output.service_plan_ids["plan-linux"] != null
    error_message = "service plan ids keyed by plan key"
  }
}
