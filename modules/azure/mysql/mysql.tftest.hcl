mock_provider "azurerm" {}

run "full_server" {
  command = plan

  variables {
    mysql_servers = {
      "orders-primary" = {
        name                              = "mysql-orders-prod-01"
        resource_group_name               = "rg-data-prod"
        location                          = "westeurope"
        sku_name                          = "GP_Standard_D2ds_v4"
        version                           = "8.0.21"
        administrator_login               = "orders_admin"
        administrator_password_wo         = "Ex4mple!Pw"
        administrator_password_wo_version = 1
        backup_retention_days             = 14
        geo_redundant_backup_enabled      = true
        zone                              = "1"
        storage = {
          size_gb           = 64
          iops              = 720
          auto_grow_enabled = true
        }
        maintenance_window = {
          day_of_week  = 3
          start_hour   = 2
          start_minute = 0
        }
        high_availability = {
          mode                      = "ZoneRedundant"
          standby_availability_zone = "2"
        }
        databases = {
          "orders" = {
            name = "orders"
          }
        }
        firewall_rules = {
          "office" = {
            name             = "office"
            start_ip_address = "203.0.113.10"
            end_ip_address   = "203.0.113.30"
          }
        }
        tags = {
          env = "prod"
        }
      }
      "orders-replica" = {
        name                = "mysql-orders-prod-replica-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
        create_mode         = "Replica"
        source_server_id    = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.DBforMySQL/flexibleServers/mysql-orders-prod-02"
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    mysql_servers = {
      "j" = {
        name                = "mysql-orders.prod"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
      }
    }
  }

  expect_failures = [var.mysql_servers]
}

run "rejects_missing_source_server_id" {
  command = plan

  variables {
    mysql_servers = {
      "orders-replica" = {
        name                = "mysql-orders-replica-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
        create_mode         = "Replica"
      }
    }
  }

  expect_failures = [var.mysql_servers]
}

run "rejects_missing_login" {
  command = plan

  variables {
    mysql_servers = {
      "orders-primary" = {
        name                = "mysql-orders-prod-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
      }
    }
  }

  expect_failures = [var.mysql_servers]
}

run "rejects_write_only_without_version" {
  command = plan

  variables {
    mysql_servers = {
      "orders-primary" = {
        name                      = "mysql-orders-prod-01"
        resource_group_name       = "rg-data-prod"
        location                  = "westeurope"
        sku_name                  = "GP_Standard_D2ds_v4"
        administrator_login       = "orders_admin"
        administrator_password_wo = "Ex4mple!Pw"
      }
    }
  }

  expect_failures = [var.mysql_servers]
}

run "rejects_dot_in_keys" {
  command = plan

  variables {
    mysql_servers = {
      "orders.primary" = {
        name                = "mysql-orders-prod-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
      }
    }
  }

  expect_failures = [var.mysql_servers]
}

run "rejects_bad_storage" {
  command = plan

  variables {
    mysql_servers = {
      "orders-primary" = {
        name                   = "mysql-orders-prod-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
        storage = {
          size_gb = 99999
        }
      }
    }
  }

  expect_failures = [var.mysql_servers]
}

run "rejects_ha_without_auto_grow" {
  command = plan

  variables {
    mysql_servers = {
      "orders-primary" = {
        name                   = "mysql-orders-prod-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
        storage = {
          size_gb           = 64
          auto_grow_enabled = false
        }
        high_availability = {
          mode = "ZoneRedundant"
        }
      }
    }
  }

  expect_failures = [var.mysql_servers]
}
