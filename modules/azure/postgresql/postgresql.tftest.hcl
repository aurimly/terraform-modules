mock_provider "azurerm" {
  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-orders-mock"
    }
  }
}

run "full_server" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-primary" = {
        name                              = "psql-orders-prod-01"
        resource_group_name               = "rg-data-prod"
        location                          = "westeurope"
        sku_name                          = "GP_Standard_D2ds_v4"
        version                           = "17"
        administrator_login               = "orders_admin"
        administrator_password_wo         = "Ex4mple!Pw"
        administrator_password_wo_version = 1
        backup_retention_days             = 14
        zone                              = "1"
        storage_mb                        = 65536
        storage_tier                      = "P30"
        auto_grow_enabled                 = true
        authentication = {
          active_directory_auth_enabled = true
          tenant_id                     = "11111111-2222-3333-4444-555555555555"
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
      "orders-private" = {
        name                              = "psql-orders-vnet-01"
        resource_group_name               = "rg-data-prod"
        location                          = "westeurope"
        sku_name                          = "GP_Standard_D2ds_v4"
        version                           = "17"
        administrator_login               = "orders_admin"
        administrator_password_wo         = "Ex4mple!Pw"
        administrator_password_wo_version = 1
        storage_type                      = "PremiumV2_LRS"
        storage_mb                        = 131072
        storage_iops                      = 5000
        storage_throughput                = 250
        delegated_subnet_id               = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-data/subnets/data"
        private_dns_zone_id               = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/orders.postgres.database.azure.com"
        public_network_access_enabled     = false
      }
      "orders-replica" = {
        name                = "psql-orders-replica-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
        create_mode         = "Replica"
        source_server_id    = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-orders-prod-02"
      }
    }
  }
}

run "rejects_bad_name" {
  command = plan

  variables {
    postgresql_servers = {
      "j" = {
        name                = "psql-orders.prod"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_default_without_version" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-primary" = {
        name                   = "psql-orders-prod-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_pitr_without_time" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-clone" = {
        name                = "psql-orders-clone-01"
        resource_group_name = "rg-data-prod"
        location            = "westeurope"
        sku_name            = "GP_Standard_D2ds_v4"
        create_mode         = "PointInTimeRestore"
        source_server_id    = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-data-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-orders-prod-02"
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_premiumv2_without_iops_throughput" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-private" = {
        name                   = "psql-orders-vnet-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
        storage_type           = "PremiumV2_LRS"
        storage_mb             = 131072
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_premiumlrs_off_set_size" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-primary" = {
        name                   = "psql-orders-prod-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
        storage_mb             = 50000
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_tenant_id_without_ad_auth" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-primary" = {
        name                   = "psql-orders-prod-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
        authentication = {
          tenant_id = "11111111-2222-3333-4444-555555555555"
        }
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_public_on_with_vnet" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-private" = {
        name                          = "psql-orders-vnet-01"
        resource_group_name           = "rg-data-prod"
        location                      = "westeurope"
        sku_name                      = "GP_Standard_D2ds_v4"
        administrator_login           = "orders_admin"
        administrator_password        = "Ex4mple!Pw"
        delegated_subnet_id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-data/subnets/data"
        private_dns_zone_id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-dns-prod/providers/Microsoft.Network/privateDnsZones/orders.postgres.database.azure.com"
        public_network_access_enabled = true
      }
    }
  }

  expect_failures = [var.postgresql_servers]
}

run "rejects_bad_firewall_ip" {
  command = plan

  variables {
    postgresql_servers = {
      "orders-primary" = {
        name                   = "psql-orders-prod-01"
        resource_group_name    = "rg-data-prod"
        location               = "westeurope"
        sku_name               = "GP_Standard_D2ds_v4"
        administrator_login    = "orders_admin"
        administrator_password = "Ex4mple!Pw"
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

  expect_failures = [var.postgresql_servers]
}
