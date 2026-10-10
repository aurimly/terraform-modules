mock_provider "azurerm" {}

run "full_accounts" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"

        automatic_failover_enabled       = true
        multiple_write_locations_enabled = false

        capabilities = {
          "vector" = {
            name = "EnableNoSQLVectorSearch"
          }
        }

        consistency_policy = {
          consistency_level       = "BoundedStaleness"
          max_interval_in_seconds = 300
          max_staleness_prefix    = 100000
        }

        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
          "secondary" = {
            location          = "northeurope"
            failover_priority = 1
            zone_redundant    = true
          }
        }

        backup = {
          type                = "Periodic"
          interval_in_minutes = 240
          retention_in_hours  = 24
        }

        sql_databases = {
          "orders" = {
            name = "orders"
            containers = {
              "items" = {
                name                = "items"
                partition_key_paths = ["/customerId"]
                autoscale_settings = {
                  max_throughput = 4000
                }
                indexing_policy = {
                  excluded_path = {
                    "payload" = {
                      path = "/payload/*"
                    }
                  }
                  included_path = {
                    "all" = {
                      path = "/*"
                    }
                  }
                }
                default_ttl = -1
              }
              "receipts" = {
                name                = "receipts"
                partition_key_paths = ["/receiptId"]
                throughput          = 400
                unique_key = {
                  "bucket" = {
                    paths = ["/bucket", "/nonce"]
                  }
                }
              }
            }
          }
        }

        tags = {
          env = "prod"
        }
      }

      "orders-mongo" = {
        name                         = "cosmos-orders-mongo-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        kind                         = "MongoDB"
        mongo_server_version         = "7.0"
        local_authentication_enabled = false

        consistency_policy = {
          consistency_level = "Session"
        }

        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }

        mongo_databases = {
          "catalog" = {
            name = "catalog"
            collections = {
              "items" = {
                name      = "items"
                shard_key = "_id"
                autoscale_settings = {
                  max_throughput = 1000
                }
                index = {
                  "lookup" = {
                    keys   = ["category"]
                    unique = false
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

run "rejects_bad_account_name" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "Cosmos_Orders_EU"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_bounded_staleness_without_bounds" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "BoundedStaleness"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_two_primary_regions" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
          "secondary" = {
            location          = "northeurope"
            failover_priority = 0
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_throughput_on_serverless" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        capabilities = {
          "serverless" = {
            name = "EnableServerless"
          }
        }
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
        sql_databases = {
          "orders" = {
            name       = "orders"
            throughput = 400
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_mongo_version_on_sql_kind" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                 = "cosmos-orders-eu-01"
        resource_group_name  = "rg-data-prod"
        location             = "westeurope"
        mongo_server_version = "7.0"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_restore_without_continuous_backup" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        create_mode         = "Restore"
        backup = {
          type                = "Periodic"
          interval_in_minutes = 240
          retention_in_hours  = 24
        }
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_container_throughput_off_step" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
        sql_databases = {
          "orders" = {
            name = "orders"
            containers = {
              "items" = {
                name                = "items"
                partition_key_paths = ["/customerId"]
                throughput          = 550
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_mongo_children_on_sql_kind" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
        mongo_databases = {
          "catalog" = {
            name = "catalog"
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_indexing_without_star_path" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
        sql_databases = {
          "orders" = {
            name = "orders"
            containers = {
              "items" = {
                name                = "items"
                partition_key_paths = ["/customerId"]
                indexing_policy = {
                  included_path = {
                    "field" = {
                      path = "/category/?"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}

run "rejects_dotted_container_key" {
  command = plan

  variables {
    cosmosdb_accounts = {
      "orders-eu" = {
        name                = "cosmos-orders-eu-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        consistency_policy = {
          consistency_level = "Session"
        }
        geo_location = {
          "primary" = {
            location          = "westeurope"
            failover_priority = 0
          }
        }
        sql_databases = {
          "orders" = {
            name = "orders"
            containers = {
              "order.items" = {
                name                = "items"
                partition_key_paths = ["/customerId"]
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.cosmosdb_accounts]
}
