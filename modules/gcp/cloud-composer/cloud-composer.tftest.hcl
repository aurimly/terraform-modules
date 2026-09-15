mock_provider "google" {}

run "environments" {
  command = plan

  variables {
    environments = {
      "main" = {
        name            = "example-airflow"
        region          = "europe-west1"
        deletion_policy = "PREVENT"
        config = {
          environment_size           = "ENVIRONMENT_SIZE_SMALL"
          enable_private_environment = true
          encryption_config = {
            kms_key_name = "projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key"
          }
          software_config = {
            image_version           = "composer-3-airflow-2.10.2-build.3"
            web_server_plugins_mode = "ENABLED"
            airflow_config_overrides = {
              "core-dags_are_paused_at_creation" = "True"
            }
            pypi_packages = {
              "numpy" = ">=1.26.0"
            }
            env_variables = {
              "EXAMPLE_VARIABLE" = "value"
            }
            cloud_data_lineage_integration = {
              enabled = true
            }
          }
          workloads_config = {
            scheduler = {
              count      = 1
              cpu        = 0.5
              memory_gb  = 2
              storage_gb = 1
            }
            triggerer = {
              cpu       = 0.5
              memory_gb = 1
              count     = 1
            }
            dag_processor = {
              count      = 1
              cpu        = 0.5
              memory_gb  = 2
              storage_gb = 1
            }
            web_server = {
              cpu        = 0.5
              memory_gb  = 2
              storage_gb = 1
            }
            worker = {
              min_count  = 1
              max_count  = 3
              cpu        = 0.5
              memory_gb  = 2
              storage_gb = 1
            }
          }
          node_config = {
            network         = "projects/example-prj/global/networks/vpc-example-prd"
            subnetwork      = "projects/example-prj/regions/europe-west1/subnetworks/example-sn"
            service_account = "composer-wkr@example-prj.iam.gserviceaccount.com"
            tags            = ["composer"]
          }
          maintenance_window = {
            start_time = "2024-01-01T00:00:00Z"
            end_time   = "2024-01-01T04:00:00Z"
            recurrence = "FREQ=WEEKLY;BYDAY=MO,TH"
          }
          recovery_config = {
            scheduled_snapshots_config = {
              enabled                    = true
              snapshot_creation_schedule = "0 0 * * *"
              time_zone                  = "UTC"
            }
          }
          data_retention_config = {
            airflow_metadata_retention_config = {
              retention_mode = "RETENTION_MODE_ENABLED"
              retention_days = 30
            }
          }
        }
      }
      "minimal" = {
        name   = "example-airflow-min"
        region = "europe-west1"
      }
    }
  }
}

run "rejects_bad_retention_mode" {
  command = plan

  variables {
    environments = {
      "main" = {
        name   = "example-airflow"
        region = "europe-west1"
        config = {
          data_retention_config = {
            airflow_metadata_retention_config = {
              retention_mode = "METADATA_RETENTION_FULL"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.environments]
}

run "rejects_gen2_image_version" {
  command = plan

  variables {
    environments = {
      "main" = {
        name   = "example-airflow"
        region = "europe-west1"
        config = {
          software_config = {
            image_version = "composer-2-airflow-2.10.2"
          }
        }
      }
    }
  }

  expect_failures = [var.environments]
}

run "rejects_airflow_env_variable" {
  command = plan

  variables {
    environments = {
      "main" = {
        name   = "example-airflow"
        region = "europe-west1"
        config = {
          software_config = {
            env_variables = {
              "AIRFLOW__CORE__XCOM_BACKEND" = "example"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.environments]
}

run "rejects_worker_min_above_max" {
  command = plan

  variables {
    environments = {
      "main" = {
        name   = "example-airflow"
        region = "europe-west1"
        config = {
          workloads_config = {
            worker = {
              min_count = 4
              max_count = 2
            }
          }
        }
      }
    }
  }

  expect_failures = [var.environments]
}
