mock_provider "azurerm" {
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.OperationalInsights/workspaces/log-ops-mock"
      workspace_id = "9861b41b-f3b1-4d9f-9f1c-93d84e4db7cc"
    }
  }
}

run "full_workspace" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                           = "log-ops-eu-01"
        resource_group_name            = "rg-monitor-prod"
        location                       = "westeurope"
        sku                            = "PerGB2018"
        retention_in_days              = 90
        internet_ingestion_access_type = "SecuredByPerimeter"
        local_authentication_enabled   = false

        identity = {
          type = "SystemAssigned"
        }

        linked_services = {
          "automation" = {
            read_access_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-automation/providers/Microsoft.Automation/automationAccounts/aaa-ops-eu"
          }
        }

        linked_storage_accounts = {
          "custom-logs" = {
            data_source_type    = "CustomLogs"
            storage_account_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor/providers/Microsoft.Storage/storageAccounts/stopslogseu01"]
          }
        }

        tags = {
          env = "prod"
        }
      }
      "reservation-eu" = {
        name                               = "log-reservation-eu-01"
        resource_group_name                = "rg-monitor-prod"
        location                           = "westeurope"
        sku                                = "CapacityReservation"
        reservation_capacity_in_gb_per_day = 100
        linked_services = {
          "cluster" = {
            write_access_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor/providers/Microsoft.OperationalInsights/clusters/cla-logs-eu"
          }
        }
      }
    }
  }
}

run "rejects_short_name" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
        sku                 = "PerGB2018"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_edge_hyphen" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log-ops-eu-"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_reservation_without_capacity_sku" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                               = "log-ops-eu-01"
        resource_group_name                = "rg-monitor-prod"
        location                           = "westeurope"
        sku                                = "PerGB2018"
        reservation_capacity_in_gb_per_day = 100
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_retention_out_of_range" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
        retention_in_days   = 20
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_linked_service_with_both_access_ids" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
        linked_services = {
          "botched-link" = {
            read_access_id  = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-automation/providers/Microsoft.Automation/automationAccounts/aaa-ops-eu"
            write_access_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor/providers/Microsoft.OperationalInsights/clusters/cla-logs-eu"
          }
        }
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_linked_service_with_neither_access_id" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
        linked_services = {
          "empty-link" = {}
        }
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_duplicate_data_source_type" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
        linked_storage_accounts = {
          "custom-logs" = {
            data_source_type    = "CustomLogs"
            storage_account_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor/providers/Microsoft.Storage/storageAccounts/stopslogseu01"]
          }
          "custom-logs-second" = {
            data_source_type    = "CustomLogs"
            storage_account_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor/providers/Microsoft.Storage/storageAccounts/stopslogseu02"]
          }
        }
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_bad_data_source_type" {
  command = plan

  variables {
    workspaces = {
      "ops-eu" = {
        name                = "log-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
        linked_storage_accounts = {
          "made-up" = {
            data_source_type    = "MadeUp"
            storage_account_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor/providers/Microsoft.Storage/storageAccounts/stopslogseu01"]
          }
        }
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_dotted_key" {
  command = plan

  variables {
    workspaces = {
      "ops.europe" = {
        name                = "log-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.workspaces]
}
