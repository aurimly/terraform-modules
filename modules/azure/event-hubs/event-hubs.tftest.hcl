mock_provider "azurerm" {
  mock_resource "azurerm_eventhub_namespace" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-messaging-prod/providers/Microsoft.EventHub/namespaces/ehn-orders-mock"
    }
  }
}

run "full_namespace" {
  command = plan

  variables {
    eventhub_namespaces = {
      "orders" = {
        name                          = "ehn-orders-prod-01"
        resource_group_name           = "rg-messaging-prod"
        location                      = "westeurope"
        sku                           = "Standard"
        capacity                      = 2
        public_network_access_enabled = false
        network_rulesets = {
          default_action = "Deny"
          ip_rules = [
            {
              ip_mask = "203.0.113.0/24"
            }
          ]
          virtual_network_rules = [
            {
              subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-data/subnets/data"
            }
          ]
          trusted_services_access_enabled = true
        }
        eventhubs = {
          "telemetry" = {
            name              = "telemetry"
            partition_count   = 8
            message_retention = 3
            capture_description = {
              enabled             = true
              encoding            = "Avro"
              interval_in_seconds = 300
              size_limit_in_bytes = 314572800
              skip_empty_archives = true
              destination = {
                archive_name_format         = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
                blob_container_name         = "capture"
                storage_account_id          = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.Storage/storageAccounts/stexampledata01"
                storage_authentication_type = "SystemAssigned"
              }
            }
            consumer_groups = {
              "reader" = {
                name          = "reader"
                user_metadata = "orders-reader"
              }
            }
          }
        }
        authorization_rules = {
          "publisher" = {
            name = "publisher"
            send = true
          }
        }
        tags = {
          env = "prod"
        }
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    eventhub_namespaces = {
      "orders" = {
        name                = "ehn-orders.prod"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.eventhub_namespaces]
}

run "rejects_userassigned_capture_without_auth_id" {
  command = plan

  variables {
    eventhub_namespaces = {
      "orders" = {
        name                = "ehn-orders-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        eventhubs = {
          "telemetry" = {
            name            = "telemetry"
            partition_count = 4
            capture_description = {
              enabled  = true
              encoding = "Avro"
              destination = {
                archive_name_format         = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
                blob_container_name         = "capture"
                storage_account_id          = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.Storage/storageAccounts/stexampledata01"
                storage_authentication_type = "UserAssigned"
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.eventhub_namespaces]
}

run "rejects_retention_14_on_standard" {
  command = plan

  variables {
    eventhub_namespaces = {
      "orders" = {
        name                = "ehn-orders-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        eventhubs = {
          "telemetry" = {
            name              = "telemetry"
            partition_count   = 4
            message_retention = 14
          }
        }
      }
    }
  }

  expect_failures = [var.eventhub_namespaces]
}

run "rejects_ruleset_deny_without_rules" {
  command = plan

  variables {
    eventhub_namespaces = {
      "orders" = {
        name                = "ehn-orders-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        network_rulesets = {
          default_action = "Deny"
        }
      }
    }
  }

  expect_failures = [var.eventhub_namespaces]
}
