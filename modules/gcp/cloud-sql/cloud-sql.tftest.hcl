mock_provider "google" {}

run "instances" {
  command = plan

  variables {
    instances = {
      "app" = {
        name              = "example-app-db"
        database_version  = "POSTGRES_16"
        region            = "europe-west4"
        tier              = "db-custom-2-7680"
        edition           = "ENTERPRISE"
        availability_type = "REGIONAL"
        backup_configuration = {
          enabled                        = true
          start_time                     = "01:00"
          point_in_time_recovery_enabled = true
          retained_backups               = 7
        }
        ip_configuration = {
          ipv4_enabled    = false
          private_network = "projects/example-prj/global/networks/vpc-example-prd"
          authorized_networks = [
            { name = "office", value = "198.51.100.0/24" },
          ]
        }
        replicas = {
          "dr" = {
            name   = "example-app-db-replica"
            region = "europe-west1"
            tier   = "db-custom-2-7680"
          }
        }
      }
      "mysql" = {
        name             = "example-mysql-db"
        database_version = "MYSQL_8_0"
        region           = "europe-west4"
        tier             = "db-custom-2-7680"
        root_password    = "example-password"
        database_flags = [
          { name = "log_bin_trust_function_creators", value = "on" },
        ]
      }
    }
  }
}

run "rejects_root_password_for_postgres" {
  command = plan

  variables {
    instances = {
      "pg" = {
        name             = "example-pg-db"
        database_version = "POSTGRES_16"
        region           = "europe-west4"
        tier             = "db-custom-2-7680"
        root_password    = "example-password"
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_allocated_ip_range_without_private_network" {
  command = plan

  variables {
    instances = {
      "app" = {
        name             = "example-app-db"
        database_version = "POSTGRES_16"
        region           = "europe-west4"
        tier             = "db-custom-2-7680"
        ip_configuration = {
          allocated_ip_range = "example-psa"
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_bad_availability_type" {
  command = plan

  variables {
    instances = {
      "app" = {
        name              = "example-app-db"
        database_version  = "POSTGRES_16"
        region            = "europe-west4"
        tier              = "db-custom-2-7680"
        availability_type = "MULTI_REGIONAL"
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_bad_backup_start_time" {
  command = plan

  variables {
    instances = {
      "app" = {
        name             = "example-app-db"
        database_version = "POSTGRES_16"
        region           = "europe-west4"
        tier             = "db-custom-2-7680"
        backup_configuration = {
          enabled    = true
          start_time = "0100"
        }
      }
    }
  }

  expect_failures = [var.instances]
}
