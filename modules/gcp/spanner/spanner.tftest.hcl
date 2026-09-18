mock_provider "google" {}

run "instances" {
  command = plan

  variables {
    instances = {
      "main" = {
        name             = "example-sp-main"
        display_name     = "Example Spanner"
        config           = "regional-europe-west1"
        processing_units = 1000
        databases = {
          "app" = {
            name                = "app-db"
            ddl                 = ["CREATE TABLE t (id INT64 NOT NULL) PRIMARY KEY(id)"]
            deletion_protection = false
            encryption_config = {
              kms_key_name = "projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key"
            }
            role_bindings = {
              "readers" = {
                role    = "roles/spanner.databaseReader"
                members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
              }
            }
          }
        }
        role_bindings = {
          "users" = {
            role    = "roles/spanner.databaseAdmin"
            members = ["group:example-data@example.com"]
          }
        }
      }
      "autoscaled" = {
        name         = "example-sp-auto"
        display_name = "Example Autoscaled"
        config       = "regional-europe-west1"
        autoscaling_config = {
          autoscaling_limits = {
            min_nodes = 1
            max_nodes = 3
          }
          autoscaling_targets = {
            high_priority_cpu_utilization_percent = 65
            total_cpu_utilization_percent         = 80
          }
          asymmetric_autoscaling_options = {
            "replica-eu4" = {
              replica_selection = { location = "europe-west4" }
              overrides = {
                autoscaling_limits = {
                  min_nodes = 1
                  max_nodes = 2
                }
              }
            }
          }
        }
      }
      "free" = {
        name          = "example-sp-free"
        display_name  = "Example Free"
        config        = "regional-europe-west1"
        instance_type = "FREE_INSTANCE"
        num_nodes     = 1
      }
    }
  }
}

run "rejects_multiple_capacity_forms" {
  command = plan

  variables {
    instances = {
      "main" = {
        name             = "example-sp-main"
        display_name     = "Example Spanner"
        config           = "regional-europe-west1"
        num_nodes        = 2
        processing_units = 2000
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_free_instance_with_edition" {
  command = plan

  variables {
    instances = {
      "free" = {
        name          = "example-sp-free"
        display_name  = "Example Free"
        config        = "regional-europe-west1"
        instance_type = "FREE_INSTANCE"
        num_nodes     = 1
        edition       = "STANDARD"
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_mixed_autoscaling_units" {
  command = plan

  variables {
    instances = {
      "main" = {
        name         = "example-sp-main"
        display_name = "Example Spanner"
        config       = "regional-europe-west1"
        autoscaling_config = {
          autoscaling_limits = {
            min_nodes            = 1
            min_processing_units = 1000
            max_processing_units = 2000
          }
          autoscaling_targets = {
            total_cpu_utilization_percent = 80
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_total_cpu_below_high_priority" {
  command = plan

  variables {
    instances = {
      "main" = {
        name         = "example-sp-main"
        display_name = "Example Spanner"
        config       = "regional-europe-west1"
        autoscaling_config = {
          autoscaling_limits = {
            min_nodes = 1
            max_nodes = 3
          }
          autoscaling_targets = {
            high_priority_cpu_utilization_percent = 80
            total_cpu_utilization_percent         = 70
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_database_kms_xor" {
  command = plan

  variables {
    instances = {
      "main" = {
        name         = "example-sp-main"
        display_name = "Example Spanner"
        config       = "regional-europe-west1"
        num_nodes    = 1
        databases = {
          "app" = {
            name = "app-db"
            encryption_config = {
              kms_key_name  = "projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key"
              kms_key_names = ["projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key"]
            }
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_duplicate_instance_role" {
  command = plan

  variables {
    instances = {
      "main" = {
        name         = "example-sp-main"
        display_name = "Example Spanner"
        config       = "regional-europe-west1"
        num_nodes    = 1
        role_bindings = {
          "a" = {
            role    = "roles/spanner.databaseAdmin"
            members = ["group:example-data@example.com"]
          }
          "b" = {
            role    = "roles/spanner.databaseAdmin"
            members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}

run "rejects_slash_in_database_key" {
  command = plan

  variables {
    instances = {
      "main" = {
        name         = "example-sp-main"
        display_name = "Example Spanner"
        config       = "regional-europe-west1"
        num_nodes    = 1
        databases = {
          "app/db" = {
            name = "app-db"
          }
        }
      }
    }
  }

  expect_failures = [var.instances]
}
