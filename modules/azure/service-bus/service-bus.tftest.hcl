mock_provider "azurerm" {
  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id       = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-messaging-prod/providers/Microsoft.ServiceBus/namespaces/sbus-orders-mock"
      endpoint = "https://sbus-orders-mock.servicebus.windows.net:443/"
    }
  }
}

run "full_namespaces" {
  command = plan

  variables {
    servicebus_namespaces = {
      "orders-premium" = {
        name                         = "sbus-orders-prod-01"
        resource_group_name          = "rg-messaging-prod"
        location                     = "westeurope"
        sku                          = "Premium"
        capacity                     = 4
        premium_messaging_partitions = 2
        identity = {
          type         = "UserAssigned"
          identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sbus-cmk"]
        }
        customer_managed_key = {
          key_vault_key_id = "https://kv-crypto-prod.vault.azure.net/keys/sbus/58c0f123456789012345678901234567"
          identity_id      = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sbus-cmk"
        }
        network_rule_set = {
          default_action = "Deny"
          ip_rules       = ["203.0.113.0/24"]
          network_rules = [
            {
              subnet_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-orders/subnets/snet-messaging"
            }
          ]
        }
        queues = {
          "settlements" = {
            name                 = "orders-settlements"
            partitioning_enabled = true
            requires_session     = true
            authorization_rules = {
              "workers" = {
                name   = "workers"
                listen = true
                send   = true
              }
            }
          }
        }
        authorization_rules = {
          "event-grid" = {
            name = "event-grid"
            send = true
          }
        }
      }
      "events-standard" = {
        name                = "sbus-events-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        topics = {
          "order-events" = {
            name = "order-events"
            subscriptions = {
              "invoice" = {
                name               = "invoice"
                max_delivery_count = 10
                rules = {
                  "sql-high-value" = {
                    name        = "high-value"
                    filter_type = "SqlFilter"
                    sql_filter  = "total_price > 1000"
                    action      = "SET sys.label = 'high-value'"
                  }
                  "corr-partner" = {
                    name        = "partner-updates"
                    filter_type = "CorrelationFilter"
                    correlation_filter = {
                      subject = "partner-update"
                      properties = {
                        partner = "acme"
                      }
                    }
                  }
                }
              }
              "sessions" = {
                name                               = "fulfilment"
                max_delivery_count                 = 5
                requires_session                   = true
                client_scoped_subscription_enabled = true
                client_scoped_subscription = {
                  client_id = "11111111-2222-3333-4444-555555555555"
                }
              }
            }
            authorization_rules = {
              "publishers" = {
                name = "publishers"
                send = true
              }
            }
          }
        }
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    servicebus_namespaces = {
      "j" = {
        name                = "sbus-orders.prod"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.servicebus_namespaces]
}

run "rejects_express_on_premium" {
  command = plan

  variables {
    servicebus_namespaces = {
      "orders-premium" = {
        name                = "sbus-orders-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        sku                 = "Premium"
        queues = {
          "hotmails" = {
            name            = "orders-hotmails"
            express_enabled = true
          }
        }
      }
    }
  }

  expect_failures = [var.servicebus_namespaces]
}

run "rejects_empty_correlation_filter" {
  command = plan

  variables {
    servicebus_namespaces = {
      "events-standard" = {
        name                = "sbus-events-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        topics = {
          "order-events" = {
            name = "order-events"
            subscriptions = {
              "invoice" = {
                name               = "invoice"
                max_delivery_count = 10
                rules = {
                  "corr-empty" = {
                    name               = "partner-updates"
                    filter_type        = "CorrelationFilter"
                    correlation_filter = {}
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.servicebus_namespaces]
}

run "rejects_cmk_on_standard" {
  command = plan

  variables {
    servicebus_namespaces = {
      "events-standard" = {
        name                = "sbus-events-prod-01"
        resource_group_name = "rg-messaging-prod"
        location            = "westeurope"
        identity = {
          type         = "UserAssigned"
          identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sbus-cmk"]
        }
        customer_managed_key = {
          key_vault_key_id = "https://kv-crypto-prod.vault.azure.net/keys/sbus/58c0f123456789012345678901234567"
          identity_id      = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sbus-cmk"
        }
      }
    }
  }

  expect_failures = [var.servicebus_namespaces]
}
