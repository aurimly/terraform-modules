mock_provider "google" {}

run "instances" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name           = "example-cache"
        region         = "europe-west4"
        memory_size_gb = 5
        redis_version  = "REDIS_7_0"
        tier           = "STANDARD_HA"
        redis_configs = {
          "maxmemory-policy" = "allkeys-lru"
        }
        persistence_config = {
          persistence_mode    = "RDB"
          rdb_snapshot_period = "ONE_HOUR"
        }
        maintenance_policy = {
          day = "MONDAY"
          start_time = {
            hours = 2
          }
        }
      }
      "session" = {
        name               = "example-session-store"
        region             = "europe-west4"
        memory_size_gb     = 10
        redis_version      = "VALKEY_7_2"
        auth_enabled       = true
        connect_mode       = "PRIVATE_SERVICE_ACCESS"
        authorized_network = "projects/example-prj/global/networks/vpc-example-prd"
        reserved_ip_range  = "example-psa-range"
      }
    }
  }
}

run "rejects_reserved_ip_range_without_psa" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name              = "example-cache"
        region            = "europe-west4"
        memory_size_gb    = 5
        redis_version     = "REDIS_7_0"
        reserved_ip_range = "example-psa-range"
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_auth_on_old_version" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name           = "example-cache"
        region         = "europe-west4"
        memory_size_gb = 5
        redis_version  = "REDIS_5_0"
        auth_enabled   = true
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_aof_persistence_mode" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name           = "example-cache"
        region         = "europe-west4"
        memory_size_gb = 5
        redis_version  = "REDIS_7_0"
        persistence_config = {
          persistence_mode    = "AOF"
          rdb_snapshot_period = "ONE_HOUR"
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_bad_maintenance_day" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name           = "example-cache"
        region         = "europe-west4"
        memory_size_gb = 5
        redis_version  = "REDIS_7_0"
        maintenance_policy = {
          day = "monday"
          start_time = {
            hours = 2
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}
