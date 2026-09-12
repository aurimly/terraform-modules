mock_provider "google" {}

run "instances" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name        = "example-cache"
        location    = "europe-west4"
        shard_count = 3
        node_type   = "SHARED_CORE_NANO"
        engine_configs = {
          "maxmemory-policy" = "volatile-ttl"
        }
        maintenance_policy = {
          day = "MONDAY"
          start_time = {
            hours = 2
          }
        }
        desired_auto_created_endpoints = [
          {
            network    = "projects/example-prj/global/networks/vpc-example-prd"
            project_id = "example-prj"
          }
        ]
      }
      "session" = {
        name           = "example-session-store"
        location       = "europe-west4"
        shard_count    = 5
        node_type      = "STANDARD_SMALL"
        engine_version = "VALKEY_7_2"
        replica_count  = 1
        zone_distribution_config = {
          mode = "SINGLE_ZONE"
          zone = "europe-west4-b"
        }
      }
    }
  }
}

run "rejects_short_name" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name        = "abc"
        location    = "europe-west4"
        shard_count = 3
        node_type   = "SHARED_CORE_NANO"
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_bad_node_type" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name        = "example-cache"
        location    = "europe-west4"
        shard_count = 3
        node_type   = "REDIS_HIGHMEM_MEDIUM"
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_single_zone_without_zone" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name        = "example-cache"
        location    = "europe-west4"
        shard_count = 3
        node_type   = "SHARED_CORE_NANO"
        zone_distribution_config = {
          mode = "SINGLE_ZONE"
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
        name        = "example-cache"
        location    = "europe-west4"
        shard_count = 3
        node_type   = "SHARED_CORE_NANO"
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

run "rejects_endpoint_bad_project" {
  command = plan

  variables {
    instances = {
      "cache" = {
        name        = "example-cache"
        location    = "europe-west4"
        shard_count = 3
        node_type   = "SHARED_CORE_NANO"
        desired_auto_created_endpoints = [
          {
            network    = "projects/example-prj/global/networks/vpc-example-prd"
            project_id = "Example_Prj"
          }
        ]
      }
    }
  }

  expect_failures = [var.instances]
}
