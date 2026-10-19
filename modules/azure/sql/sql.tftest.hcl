mock_provider "azurerm" {
  # azurerm 5.x parses referenced resource IDs at plan time — the mock's
  # synthetic IDs must be real ARM IDs.
  mock_resource "azurerm_mssql_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Sql/servers/sql"
    }
  }

  mock_resource "azurerm_mssql_elasticpool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Sql/servers/sql/elasticPools/pool"
    }
  }

  mock_resource "azurerm_mssql_database" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Sql/servers/sql/databases/db"
    }
  }
}

run "full_server" {
  command = plan

  variables {
    sql_servers = {
      "orders-primary" = {
        name                                    = "sql-orders-prod-01"
        resource_group_name                     = "rg-data-prod"
        location                                = "westeurope"
        administrator_login                     = "orders_admin"
        administrator_login_password_wo         = "Ex4mple!Pw"
        administrator_login_password_wo_version = 1
        azuread_administrator = {
          login_username              = "sql-admins"
          object_id                   = "11111111-2222-3333-4444-555555555555"
          azuread_authentication_only = false
        }
        minimum_tls_version = "1.2"

        elastic_pools = {
          "main" = {
            name = "pool-orders-prod"
            sku = {
              name     = "GP_Gen5"
              tier     = "GeneralPurpose"
              capacity = 4
              family   = "Gen5"
            }
            max_size_gb = 1024
            per_database_settings = {
              min_capacity = 0.5
              max_capacity = 4
            }
            tags = {
              env = "prod"
            }
          }
        }

        databases = {
          "orders" = {
            name                 = "orders"
            collation            = "SQL_Latin1_General_CP1_CI_AS"
            sku_name             = "GP_Gen5_2"
            max_size_gb          = 128
            storage_account_type = "GeoZone"
            short_term_retention_policy = {
              retention_days           = 21
              backup_interval_in_hours = 12
            }
            long_term_retention_policy = {
              weekly_retention  = "P1W"
              monthly_retention = "P1M"
              yearly_retention  = "P1Y"
              week_of_year      = 1
            }
          }
          "pooled" = {
            name             = "orders-pooled"
            sku_name         = "ElasticPool"
            elastic_pool_key = "main"
          }
          "orders-copy" = {
            name                        = "orders-copy-01"
            create_mode                 = "Copy"
            creation_source_database_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.Sql/servers/sql-orders-prod-02/databases/orders"
          }
        }

        firewall_rules = {
          "office" = {
            name             = "office"
            start_ip_address = "203.0.113.10"
            end_ip_address   = "203.0.113.30"
          }
        }

        failover_groups = {
          "main" = {
            name              = "fog-orders-prod"
            partner_server_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-dr/providers/Microsoft.Sql/servers/sql-orders-dr-01"
            database_keys     = ["orders"]
            read_write_endpoint_failover_policy = {
              mode          = "Automatic"
              grace_minutes = 60
            }
          }
        }

        tags = {
          env = "prod"
        }
      }
    }
  }
}

run "entra_only_without_sql_credentials" {
  command = plan

  variables {
    sql_servers = {
      "orders-entra" = {
        name                = "sql-orders-entra-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        azuread_administrator = {
          login_username              = "sql-admins"
          object_id                   = "11111111-2222-3333-4444-555555555555"
          azuread_authentication_only = true
        }
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "Sql_Orders_PROD"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_missing_credentials" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                = "sql-orders-prod-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_write_only_without_version" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                            = "sql-orders-prod-01"
        resource_group_name             = "rg-data-prod"
        location                        = "westeurope"
        administrator_login             = "orders_admin"
        administrator_login_password_wo = "Ex4mple!Pw"
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_dangling_elastic_pool_key" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        databases = {
          "pooled" = {
            name             = "orders-pooled"
            sku_name         = "ElasticPool"
            elastic_pool_key = "missing"
          }
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_pooled_database_with_own_sku" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        elastic_pools = {
          "main" = {
            name = "pool-orders-prod"
            sku = {
              name     = "GP_Gen5"
              tier     = "GeneralPurpose"
              capacity = 4
            }
            max_size_gb = 1024
            per_database_settings = {
              min_capacity = 0.5
              max_capacity = 4
            }
          }
        }
        databases = {
          "pooled" = {
            name             = "orders-pooled"
            sku_name         = "GP_Gen5_2"
            elastic_pool_key = "main"
          }
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_copy_without_source" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        databases = {
          "copy" = {
            name        = "orders-copy-01"
            create_mode = "Copy"
          }
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_automatic_failover_without_grace" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        failover_groups = {
          "main" = {
            name              = "fog-orders-prod"
            partner_server_id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-dr/providers/Microsoft.Sql/servers/sql-orders-dr-01"
            read_write_endpoint_failover_policy = {
              mode = "Automatic"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_user_assigned_identity_without_primary" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        identity = {
          type         = "UserAssigned"
          identity_ids = ["/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-iam-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sql-orders"]
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_retention_days_out_of_range" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        databases = {
          "orders" = {
            name = "orders"
            short_term_retention_policy = {
              retention_days = 40
            }
          }
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_dot_in_keys" {
  command = plan

  variables {
    sql_servers = {
      "orders.primary" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
      }
    }
  }

  expect_failures = [var.sql_servers]
}

run "rejects_bad_firewall_address" {
  command = plan

  variables {
    sql_servers = {
      "orders" = {
        name                         = "sql-orders-prod-01"
        resource_group_name          = "rg-data-prod"
        location                     = "westeurope"
        administrator_login          = "orders_admin"
        administrator_login_password = "Ex4mple!Pw"
        firewall_rules = {
          "office" = {
            name             = "office"
            start_ip_address = "203.0.113.0/24"
            end_ip_address   = "203.0.113.255"
          }
        }
      }
    }
  }

  expect_failures = [var.sql_servers]
}
