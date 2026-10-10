mock_provider "azurerm" {
  mock_resource "azurerm_redis_cache" {
    defaults = {
      id       = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-cache-prod/providers/Microsoft.Cache/redis/cache-sessions-mock"
      hostname = "cache-sessions-mock.redis.cache.windows.net"
      ssl_port = 6380
    }
  }
}

run "full_cache" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "P"
        sku_name            = "Premium"

        subnet_id   = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-net-prod/providers/Microsoft.Network/virtualNetworks/vnet-cache/subnets/redis"
        shard_count = 2

        redis_configuration = {
          rdb_backup_enabled            = true
          rdb_backup_frequency          = 360
          rdb_storage_connection_string = "DefaultEndpointsProtocol=https;AccountName=stub;AccountKey=stub"
        }

        patch_schedule = {
          "monday" = {
            day_of_week    = "Monday"
            start_hour_utc = 2
          }
        }

        firewall_rules = {
          "office" = {
            name     = "office"
            start_ip = "203.0.113.10"
            end_ip   = "203.0.113.30"
          }
        }

        tags = {
          env = "prod"
        }
      }
      "sessions-us" = {
        name                = "cache-sessions-us-01"
        resource_group_name = "rg-cache-prod"
        location            = "eastus"
        capacity            = 2
        family              = "P"
        sku_name            = "Premium"
      }
    }

    linked_servers = {
      "sessions-pair" = {
        target_cache_key = "sessions-eu"
        linked_cache_key = "sessions-us"
        server_role      = "Secondary"
      }
    }
  }
}

run "rejects_family_sku_pairing" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "C"
        sku_name            = "Premium"
      }
    }
  }

  expect_failures = [var.redis_caches]
}

run "rejects_capacity_on_p_family" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 0
        family              = "P"
        sku_name            = "Premium"
      }
    }
  }

  expect_failures = [var.redis_caches]
}

run "rejects_shards_on_standard" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "C"
        sku_name            = "Standard"
        shard_count         = 2
      }
    }
  }

  expect_failures = [var.redis_caches]
}

run "rejects_noauth_without_subnet" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "C"
        sku_name            = "Standard"
        redis_configuration = {
          authentication_enabled = false
        }
      }
    }
  }

  expect_failures = [var.redis_caches]
}

run "rejects_rdb_without_connection_string" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "P"
        sku_name            = "Premium"
        redis_configuration = {
          rdb_backup_enabled = true
        }
      }
    }
  }

  expect_failures = [var.redis_caches]
}

run "rejects_keyless_auth_without_entra" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                               = "cache-sessions-eu-01"
        resource_group_name                = "rg-cache-prod"
        location                           = "westeurope"
        capacity                           = 2
        family                             = "C"
        sku_name                           = "Standard"
        access_keys_authentication_enabled = false
      }
    }
  }

  expect_failures = [var.redis_caches]
}

run "rejects_linked_server_unknown_key" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "P"
        sku_name            = "Premium"
      }
    }

    linked_servers = {
      "botched-pair" = {
        target_cache_key = "sessions-eu"
        linked_cache_key = "sessions-apac"
        server_role      = "Secondary"
      }
    }
  }

  expect_failures = [var.linked_servers]
}

run "rejects_non_ipv4_firewall_rule" {
  command = plan

  variables {
    redis_caches = {
      "sessions-eu" = {
        name                = "cache-sessions-eu-01"
        resource_group_name = "rg-cache-prod"
        location            = "westeurope"
        capacity            = 2
        family              = "P"
        sku_name            = "Premium"
        firewall_rules = {
          "office" = {
            name     = "office"
            start_ip = "203.0.113.0/24"
            end_ip   = "203.0.113.255"
          }
        }
      }
    }
  }

  expect_failures = [var.redis_caches]
}
