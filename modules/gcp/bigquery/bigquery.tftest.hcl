mock_provider "google" {}

run "datasets" {
  command = plan

  variables {
    datasets = {
      "analytics" = {
        dataset_id                  = "example_analytics"
        location                    = "EU"
        friendly_name               = "Example analytics"
        max_time_travel_hours       = 72
        storage_billing_model       = "PHYSICAL"
        default_table_expiration_ms = 172800000
        default_encryption_configuration = {
          kms_key_name = "projects/example-prj/locations/europe-west4/keyRings/example-ring/cryptoKeys/example-key"
        }
        access_grants = {
          "group" = {
            role           = "WRITER"
            group_by_email = "example-analytics@example.com"
          }
          "authorized-view" = {
            view = {
              project_id = "example-prj"
              dataset_id = "example_source"
              table_id   = "example_source_view"
            }
          }
        }
        tables = {
          "events" = {
            table_id                 = "example_events"
            require_partition_filter = true
            clustering               = ["event_type"]
            schema                   = "[{\"name\": \"event_id\", \"type\": \"STRING\", \"mode\": \"REQUIRED\"}, {\"name\": \"event_at\", \"type\": \"TIMESTAMP\", \"mode\": \"REQUIRED\"}, {\"name\": \"event_type\", \"type\": \"STRING\"}]"
            time_partitioning = {
              type          = "DAY"
              field         = "event_at"
              expiration_ms = 7776000000
            }
          }
          "latest" = {
            table_id                     = "example_latest_events"
            ignore_auto_generated_schema = true
            view = {
              query          = "SELECT event_id FROM example_analytics.example_events"
              use_legacy_sql = false
            }
          }
        }
      }
      "exports" = {
        dataset_id = "example_exports"
        location   = "europe-west4"
        role_bindings = {
          "viewers" = {
            role    = "roles/bigquery.dataViewer"
            members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
          }
          "editors" = {
            role    = "roles/bigquery.dataEditor"
            members = ["serviceAccount:ci@example-prj.iam.gserviceaccount.com"]
            condition = {
              title      = "ci-tables-only"
              expression = "resource.name.startsWith(\"projects/example-prj/datasets/example_exports/tables/ci_\")"
            }
          }
        }
        tables = {
          "schedules" = {
            table_id            = "example_schedules"
            deletion_protection = false
            schema              = "[{\"name\": \"schedule_id\", \"type\": \"STRING\", \"mode\": \"REQUIRED\"}, {\"name\": \"runs_at\", \"type\": \"TIMESTAMP\"}]"
            range_partitioning = {
              field = "runs_at"
              range = { start = 0, end = 1000000, interval = 1000 }
            }
          }
        }
      }
    }
  }
}

run "rejects_hyphens_in_dataset_id" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example-dataset"
        location   = "EU"
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_bad_location" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "europe_west4"
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_legacy_role_in_role_bindings" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        role_bindings = {
          "viewers" = {
            role    = "READER"
            members = ["group:example-viewers@example.com"]
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_access_grants_with_role_bindings" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        access_grants = {
          "group" = {
            role           = "WRITER"
            group_by_email = "example-analytics@example.com"
          }
        }
        role_bindings = {
          "viewers" = {
            role    = "roles/bigquery.dataViewer"
            members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_bad_time_partitioning_type" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        tables = {
          "t" = {
            table_id = "example_table"
            schema   = "[{\"name\": \"event_at\", \"type\": \"TIMESTAMP\"}]"
            time_partitioning = {
              type = "WEEK"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_more_than_four_clustering_columns" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        tables = {
          "t" = {
            table_id   = "example_table"
            schema     = "[{\"name\": \"event_at\", \"type\": \"TIMESTAMP\"}]"
            clustering = ["a", "b", "c", "d", "e"]
            time_partitioning = {
              type = "DAY"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_view_with_schema" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        tables = {
          "t" = {
            table_id = "example_view"
            schema   = "[{\"name\": \"event_id\", \"type\": \"STRING\"}]"
            view = {
              query = "SELECT 1"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_low_max_time_travel_hours" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id            = "example_dataset"
        location              = "EU"
        max_time_travel_hours = 24
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_low_default_table_expiration" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id                  = "example_dataset"
        location                    = "EU"
        default_table_expiration_ms = 3599999
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_inverted_range_partitioning" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        tables = {
          "t" = {
            table_id = "example_table"
            schema   = "[{\"name\": \"n\", \"type\": \"INT64\"}]"
            range_partitioning = {
              field = "n"
              range = { start = 100, end = 50, interval = 10 }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_slash_in_keys" {
  command = plan

  variables {
    datasets = {
      "bad/labeled" = {
        dataset_id = "example_dataset"
        location   = "EU"
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_connection_id_with_external_schema" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        tables = {
          "t" = {
            table_id = "example_table"
            schema   = "[{\"name\": \"id\", \"type\": \"STRING\"}]"
            external_data_configuration = {
              autodetect    = true
              source_format = "CSV"
              source_uris   = ["gs://example-bucket/example.csv"]
              schema        = "[{\"name\": \"id\", \"type\": \"STRING\"}]"
              connection_id = "projects/example-prj/locations/europe-west4/connections/example-federation"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_external_table_without_schema_or_autodetect" {
  command = plan

  variables {
    datasets = {
      "bad" = {
        dataset_id = "example_dataset"
        location   = "EU"
        tables = {
          "t" = {
            table_id = "example_table"
            external_data_configuration = {
              source_format = "CSV"
              source_uris   = ["gs://example-bucket/example.csv"]
              csv_options = {
                quote            = "\""
                skip_leading_rows = 1
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.datasets]
}
