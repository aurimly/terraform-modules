mock_provider "azurerm" {
  mock_resource "azurerm_container_app" {
    defaults = {
      id                            = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/containerApps/api-mock"
      location                      = "northeurope"
      latest_revision_fqdn          = "api-mock.northeurope.azurecontainerapps.io"
      latest_revision_name          = "api-mock--mock"
      outbound_ip_addresses         = ["52.0.0.1"]
      custom_domain_verification_id = "mock"
    }
  }
}

run "full_apps" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Multiple"

        identity = {
          type         = "UserAssigned"
          identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-api-registry"]
        }

        secret = {
          "db-password" = {
            name  = "db-password"
            value = "example-placeholder"
          }
          "kv-connection" = {
            name                = "kv-connection"
            key_vault_secret_id = "https://kv-crypto-prod.vault.azure.net/secrets/app-connection"
            identity            = "System"
          }
        }

        registry = {
          "primary" = {
            server   = "crplatformprod.azurecr.io"
            identity = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-api-registry"
          }
        }

        dapr = {
          app_id   = "api"
          app_port = 3000
        }

        template = {
          min_replicas = 1
          max_replicas = 20

          container = {
            "api" = {
              name    = "api"
              image   = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu     = 0.5
              memory  = "1.0Gi"
              args    = ["--serve"]
              command = ["python", "app.py"]
              env = {
                "DB_PASSWORD" = {
                  secret_name = "db-password"
                }
                "APP_MODE" = {
                  value = "prod"
                }
              }
              liveness_probe = {
                "http" = {
                  transport = "HTTP"
                  port      = 3000
                  path      = "/healthz"
                  header = {
                    "x-session" = {
                      name  = "X-Session"
                      value = "probe"
                    }
                  }
                  failure_count_threshold = 4
                }
              }
              readiness_probe = {
                "https" = {
                  transport               = "HTTPS"
                  port                    = 3000
                  path                    = "/ready"
                  success_count_threshold = 2
                }
              }
              startup_probe = {
                "tcp" = {
                  transport = "TCP"
                  port      = 3000
                }
              }
              volume_mounts = {
                "certificates" = {
                  path = "/mnt/certs"
                }
              }
            }
          }

          init_container = {
            "waiter" = {
              name    = "wait-for-migrations"
              image   = "crplatformprod.azurecr.io/tools/waiter:v1"
              cpu     = 0.25
              memory  = "0.5Gi"
              command = ["sleep", "30"]
              env = {
                "WAIT_FOR" = {
                  value = "migrations"
                }
              }
              volume_mounts = {
                "certificates" = {
                  path = "/mnt/certs"
                }
              }
            }
          }

          http_scale_rule = {
            "http-traffic" = {
              concurrent_requests = "100"
              authentication = {
                "session" = {
                  secret_name       = "db-password"
                  trigger_parameter = "x-session-header"
                }
              }
            }
          }

          volume = {
            "certificates" = {
              storage_type = "AzureFile"
              storage_name = "certs-share"
            }
          }
        }

        ingress = {
          target_port      = 3000
          external_enabled = true
          transport        = "auto"

          cors = {
            allowed_origins = ["https://app.example.com"]
            allowed_methods = ["GET", "POST"]
          }

          ip_security_restriction = {
            "office" = {
              name             = "office-cidrs"
              action           = "Allow"
              ip_address_range = "203.0.113.0/24"
            }
          }

          traffic_weight = {
            "latest" = {
              latest_revision = true
              percentage      = 100
            }
          }
        }

        max_inactive_revisions = 5

        tags = {
          app = "api"
        }
      }
      "invoice-processor" = {
        name                         = "invoice-processor-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"

        secret = {
          "queue-identity" = {
            name  = "queue-identity"
            value = "example-placeholder"
          }
        }

        template = {
          container = {
            "processor" = {
              name   = "processor"
              image  = "crplatformprod.azurecr.io/invoice-processor:v3"
              cpu    = 0.25
              memory = "0.5Gi"
            }
          }

          azure_queue_scale_rule = {
            "invoice-queue" = {
              queue_name   = "invoice-orders"
              queue_length = 5
              authentication = {
                "storage" = {
                  secret_name       = "queue-identity"
                  trigger_parameter = "identity"
                }
              }
            }
          }
        }
        tags = {
          app = "invoice-processor"
        }
      }
    }
  }
}

run "rejects_bad_app_name" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api--prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_weights_not_summing_to_100" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
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
              percentage      = 90
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_exposed_port_on_non_tcp" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        }
        ingress = {
          target_port  = 3000
          exposed_port = 5555
          traffic_weight = {
            "latest" = {
              latest_revision = true
              percentage      = 100
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_secret_without_value_or_vault" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        secret = {
          "candidate" = {
            name = "candidate"
          }
        }
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_dangling_env_secret_reference" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
              env = {
                "DB_PASSWORD" = {
                  secret_name = "db-password"
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_mount_without_volume" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
              volume_mounts = {
                "not-declared" = {
                  path = "/mnt/data"
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_queue_rule_without_authentication" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
          azure_queue_scale_rule = {
            "invoice-queue" = {
              queue_name     = "invoice-orders"
              queue_length   = 5
              authentication = {}
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}

run "rejects_both_registry_auth_mechanisms" {
  command = plan

  variables {
    container_apps = {
      "api" = {
        name                         = "api-prod"
        resource_group_name          = "rg-platform-prod"
        container_app_environment_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-platform-prod/providers/Microsoft.App/managedEnvironments/cae-eu-prod-01"
        revision_mode                = "Single"
        secret = {
          "cr-password" = {
            name  = "cr-password"
            value = "example-placeholder"
          }
        }
        registry = {
          "primary" = {
            server               = "crplatformprod.azurecr.io"
            username             = "cruser"
            password_secret_name = "cr-password"
            identity             = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-identity-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-api-registry"
          }
        }
        template = {
          container = {
            "api" = {
              name   = "api"
              image  = "crplatformprod.azurecr.io/api:v1.2.3"
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.container_apps]
}
