mock_provider "azurerm" {
  mock_resource "azurerm_monitor_action_group" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/actionGroups/aa-mock"
    }
  }

  mock_resource "azurerm_monitor_metric_alert" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/metricAlerts/ma-mock"
    }
  }

  mock_resource "azurerm_monitor_activity_log_alert" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/activityLogAlerts/ala-mock"
    }
  }

  mock_resource "azurerm_monitor_scheduled_query_rules_alert_v2" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/scheduledQueryRules/sqr-mock"
    }
  }

  mock_resource "azurerm_monitor_diagnostic_setting" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/diagnosticSettings/ds-mock"
    }
  }
}

run "full_monitor" {
  command = plan

  variables {
    action_groups = {
      "ops" = {
        name                = "aa-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        short_name          = "ops-eu"
        location            = "global"

        email_receivers = {
          "sre" = {
            name          = "sre"
            email_address = "sre@example.invalid"
          }
        }

        webhook_receivers = {
          "pagerduty" = {
            name                    = "pagerduty"
            service_uri             = "https://events.pagerduty.example.invalid/webhook"
            use_common_alert_schema = true

            aad_auth = {
              object_id      = "00000000-0000-0000-0000-000000000000"
              identifier_uri = "https://example.invalid"
              tenant_id      = "11111111-2222-3333-4444-555555555555"
            }
          }
        }
      }
    }

    metric_alerts = {
      "vm-cpu" = {
        name                = "ma-vm-cpu"
        resource_group_name = "rg-monitor-prod"
        scopes              = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.Compute/virtualMachines/vm-01"]
        severity            = 1
        window_size         = "PT15M"
        frequency           = "PT5M"

        criteria = {
          "cpu" = {
            metric_namespace = "Microsoft.Compute/virtualMachines"
            metric_name      = "Percentage CPU"
            aggregation      = "Average"
            operator         = "GreaterThan"
            threshold        = 90

            dimensions = {
              "vm" = {
                name     = "VMName"
                operator = "Include"
                values   = ["vm-01"]
              }
            }
          }
        }

        actions = {
          "ops" = {
            action_group_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/actionGroups/aa-ops-eu-01"
          }
        }
      }
    }

    activity_log_alerts = {
      "admin" = {
        name                = "ala-admin"
        resource_group_name = "rg-monitor-prod"
        scopes              = ["/subscriptions/11111111-2222-3333-4444-555555555555"]

        criteria = {
          category = "Administrative"
          caller   = "someone@example.invalid"
          statuses = ["Succeeded"]
        }

        actions = {
          "ops" = {
            action_group_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.Insights/actionGroups/aa-ops-eu-01"
          }
        }
      }
    }

    scheduled_query_rules = {
      "storage-4xx" = {
        name                 = "sqr-storage-4xx"
        resource_group_name  = "rg-monitor-prod"
        location             = "westeurope"
        scopes               = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/stapplogseu01"]
        severity             = 2
        evaluation_frequency = "PT5M"
        window_duration      = "PT1H"

        identity = {
          type = "SystemAssigned"
        }

        criteria = {
          "requests" = {
            query                   = "StorageBlobLogs | where StatusText startswith '4'"
            operator                = "GreaterThan"
            threshold               = 100
            time_aggregation_method = "Count"

            failing_periods = {
              minimum_failing_periods_to_trigger_alert = 1
              number_of_evaluation_periods             = 1
            }
          }
        }

        action = {
          email_subject = "blob 4xx spike"
        }
      }
    }

    diagnostic_settings = {
      "workspace" = {
        name                           = "ds-workspace"
        target_resource_id             = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.KeyVault/vaults/kv-app"
        log_analytics_workspace_id     = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.OperationalInsights/workspaces/log-ops-eu-01"
        log_analytics_destination_type = "Dedicated"

        logs = [
          {
            category = "AuditEvent"
          },
          {
            category_group = "allLogs"
          }
        ]

        metric_categories = ["AllMetrics"]
      }
    }
  }
}

run "rejects_metric_alert_with_two_criteria_types" {
  command = plan

  variables {
    action_groups = {}

    activity_log_alerts = {}

    scheduled_query_rules = {}

    diagnostic_settings = {}

    metric_alerts = {
      "vm-cpu" = {
        name                = "ma-vm-cpu"
        resource_group_name = "rg-monitor-prod"
        scopes              = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.Compute/virtualMachines/vm-01"]

        criteria = {
          "cpu" = {
            metric_namespace = "Microsoft.Compute/virtualMachines"
            metric_name      = "Percentage CPU"
            aggregation      = "Average"
            operator         = "GreaterThan"
            threshold        = 90
          }
        }

        web_test_criteria = {
          web_test_id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.Insights/webTests/wt-01"
          component_id          = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.Insights/components/ai-01"
          failed_location_count = 2
        }
      }
    }
  }

  expect_failures = [var.metric_alerts]
}

run "rejects_diagnostic_setting_without_destination" {
  command = plan

  variables {
    action_groups = {}

    metric_alerts = {}

    activity_log_alerts = {}

    scheduled_query_rules = {}

    diagnostic_settings = {
      "workspace" = {
        name               = "ds-workspace"
        target_resource_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.KeyVault/vaults/kv-app"

        logs = [
          {
            category = "AuditEvent"
          }
        ]
      }
    }
  }

  expect_failures = [var.diagnostic_settings]
}

run "rejects_duplicate_receiver_name_across_types" {
  command = plan

  variables {
    metric_alerts = {}

    activity_log_alerts = {}

    scheduled_query_rules = {}

    diagnostic_settings = {}

    action_groups = {
      "ops" = {
        name                = "aa-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        short_name          = "ops-eu"

        email_receivers = {
          "sre" = {
            name          = "sre"
            email_address = "sre@example.invalid"
          }
        }

        webhook_receivers = {
          "slack" = {
            name        = "SRE"
            service_uri = "https://hooks.slack.example.invalid/services/a/b/c"
          }
        }
      }
    }
  }

  expect_failures = [var.action_groups]
}

run "rejects_dotted_key" {
  command = plan

  variables {
    metric_alerts = {}

    activity_log_alerts = {}

    scheduled_query_rules = {}

    diagnostic_settings = {}

    action_groups = {
      "ops.eu" = {
        name                = "aa-ops-eu-01"
        resource_group_name = "rg-monitor-prod"
        short_name          = "ops-eu"

        email_receivers = {
          "sre" = {
            name          = "sre"
            email_address = "sre@example.invalid"
          }
        }
      }
    }
  }

  expect_failures = [var.action_groups]
}

run "rejects_log_entry_with_both_category_and_group" {
  command = plan

  variables {
    action_groups = {}

    metric_alerts = {}

    activity_log_alerts = {}

    scheduled_query_rules = {}

    diagnostic_settings = {
      "workspace" = {
        name                       = "ds-workspace"
        target_resource_id         = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-app/providers/Microsoft.KeyVault/vaults/kv-app"
        log_analytics_workspace_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.OperationalInsights/workspaces/log-ops-eu-01"

        logs = [
          {
            category       = "AuditEvent"
            category_group = "allLogs"
          }
        ]
      }
    }
  }

  expect_failures = [var.diagnostic_settings]
}

run "rejects_itsm_ticket_configuration_missing_keys" {
  command = plan

  variables {
    metric_alerts = {}

    activity_log_alerts = {}

    scheduled_query_rules = {}

    diagnostic_settings = {}

    action_groups = {
      "itsm" = {
        name                = "aa-itsm"
        resource_group_name = "rg-monitor-prod"
        short_name          = "itsm"

        itsm_receivers = {
          "servicenow" = {
            name                 = "servicenow"
            workspace_id         = "11111111-2222-3333-4444-555555555555|aaaa1111-bbbb-4222-8333-ccccdddd0000"
            connection_id        = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-monitor-prod/providers/Microsoft.ServerManagement/nodes/itsm-connection"
            ticket_configuration = "{}"
            region               = "westeurope"
          }
        }
      }
    }
  }

  expect_failures = [var.action_groups]
}
