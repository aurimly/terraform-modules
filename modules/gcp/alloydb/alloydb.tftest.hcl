mock_provider "google" {}

run "clusters" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id       = "example-app-cluster"
        location         = "europe-west4"
        database_version = "POSTGRES_15"
        network_config = {
          network = "projects/example-prj/global/networks/vpc-example-prd"
        }
        initial_user = {
          user     = "postgres"
          password = "example-password"
        }
        continuous_backup_config = {
          enabled              = true
          recovery_window_days = 14
        }
        automated_backup_policy = {
          enabled       = true
          location      = "europe-west4"
          backup_window = "1800s"
          labels        = { team = "data" }
          weekly_schedule = {
            days_of_week = ["MONDAY"]
            start_times  = [{ hours = 23 }]
          }
          quantity_based_retention = { count = 2 }
        }
        maintenance_update_policy = {
          maintenance_windows = [
            { day = "MONDAY", start_time = { hours = 2 } },
          ]
        }
        instances = {
          "primary" = {
            instance_id       = "example-app-primary"
            instance_type     = "PRIMARY"
            display_name      = "example-primary"
            availability_type = "REGIONAL"
            machine_config    = { cpu_count = 8, machine_type = "n2-highmem-8" }
            client_connection_config = {
              ssl_config = { ssl_mode = "ENCRYPTED_ONLY" }
            }
            database_flags = { "log_min_duration_statement" = "1000" }
          }
          "reads" = {
            instance_id      = "example-app-reads"
            instance_type    = "READ_POOL"
            read_pool_config = { node_count = 2 }
            gce_zone         = "europe-west4-a"
          }
        }
        backups = {
          "daily" = {
            backup_id = "example-app-backup"
            location  = "europe-west4"
            type      = "ON_DEMAND"
          }
        }
      }
      "secondary" = {
        cluster_id      = "example-app-secondary"
        location        = "europe-west1"
        cluster_type    = "SECONDARY"
        deletion_policy = "FORCE"
        network_config = {
          network = "projects/example-prj/global/networks/vpc-example-prd"
        }
        secondary_config = {
          primary_cluster_name = "projects/example-prj/locations/europe-west4/clusters/example-app-cluster"
        }
        continuous_backup_config = {
          enabled = false
        }
        instances = {
          "secondary" = {
            instance_id    = "example-app-secondary"
            instance_type  = "SECONDARY"
            machine_config = { cpu_count = 2 }
          }
        }
      }
    }
  }
}

run "rejects_bad_ssl_mode" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id = "example-app-cluster"
        location   = "europe-west4"
        instances = {
          "primary" = {
            instance_id   = "example-app-primary"
            instance_type = "PRIMARY"
            client_connection_config = {
              ssl_config = { ssl_mode = "VERIFY_CA" }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_read_pool_without_read_pool_config" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id = "example-app-cluster"
        location   = "europe-west4"
        instances = {
          "reads" = {
            instance_id   = "example-app-reads"
            instance_type = "READ_POOL"
          }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_retention_xor" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id = "example-app-cluster"
        location   = "europe-west4"
        automated_backup_policy = {
          time_based_retention     = { retention_period = "86400s" }
          quantity_based_retention = { count = 2 }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_short_backup_window" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id = "example-app-cluster"
        location   = "europe-west4"
        automated_backup_policy = {
          backup_window            = "60s"
          quantity_based_retention = { count = 2 }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_secondary_config_mismatch" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id   = "example-app-cluster"
        location     = "europe-west4"
        cluster_type = "PRIMARY"
        secondary_config = {
          primary_cluster_name = "projects/example-prj/locations/europe-west4/clusters/example-src"
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

run "rejects_slash_in_instance_key" {
  command = plan

  variables {
    clusters = {
      "app" = {
        cluster_id = "example-app-cluster"
        location   = "europe-west4"
        instances = {
          "a/b" = {
            instance_id   = "example-app-primary"
            instance_type = "PRIMARY"
          }
        }
      }
    }
  }

  expect_failures = [var.clusters]
}
