mock_provider "google" {}

run "full" {
  command = plan

  variables {
    private_connections = {
      "peering" = {
        private_connection_id = "example-ds-connection"
        display_name          = "Example Private Connection"
        location              = "europe-west1"
        vpc_peering_config = {
          vpc    = "projects/example-prj/global/networks/example-net"
          subnet = "10.0.0.0/29"
        }
      }
      "psc" = {
        private_connection_id = "example-ds-psc"
        display_name          = "Example PSC Connection"
        location              = "europe-west1"
        psc_interface_config = {
          network_attachment = "projects/example-prj/regions/europe-west1/networkAttachments/example-att"
        }
      }
    }
    connection_profiles = {
      "pg-source" = {
        connection_profile_id = "example-ds-pg"
        display_name          = "Example PostgreSQL Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
        private_connectivity = {
          private_connection_key = "peering"
        }
      }
      "bq-dest" = {
        connection_profile_id = "example-ds-bq"
        display_name          = "Example BigQuery Destination"
        location              = "europe-west1"
        bigquery_profile      = true
      }
      "mysql-source" = {
        connection_profile_id = "example-ds-mysql"
        display_name          = "Example MySQL Source"
        location              = "europe-west1"
        mysql_profile = {
          hostname                       = "example-mysql.example.internal"
          username                       = "datastream"
          secret_manager_stored_password = "projects/example-prj/secrets/example-secret/versions/1"
        }
        forward_ssh_connectivity = {
          hostname = "example-bastion.example.internal"
          username = "tunnel"
        }
      }
      "gcs-dest" = {
        connection_profile_id = "example-ds-gcs"
        display_name          = "Example GCS Destination"
        location              = "europe-west1"
        gcs_profile = {
          bucket    = "example-bucket"
          root_path = "/data"
        }
      }
      "mongodb-source" = {
        connection_profile_id = "example-ds-mongo"
        display_name          = "Example MongoDB Source"
        location              = "europe-west1"
        mongodb_profile = {
          username              = "datastream"
          host_addresses        = [{ hostname = "example-mongo.example.internal", port = 27017 }]
          password              = "example-password"
          srv_connection_format = true
        }
      }
      "external-pg" = {
        connection_profile_id = "example-ds-external"
        display_name          = "Example External Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname                       = "external-db.example.internal"
          username                       = "datastream"
          secret_manager_stored_password = "projects/example-prj/secrets/example-secret/versions/1"
          database                       = "appdb"
        }
      }
    }
    streams = {
      "pg-to-bq" = {
        stream_id    = "example-ds-stream-bq"
        location     = "europe-west1"
        display_name = "Example PostgreSQL to BigQuery"
        source_config = {
          source_connection_profile_key = "pg-source"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
            include_objects = {
              postgresql_schemas = {
                "app" = {
                  schema = "app"
                  postgresql_tables = {
                    "orders" = {
                      table              = "orders"
                      postgresql_columns = [{ column = "id", primary_key = true }]
                    }
                  }
                }
              }
            }
          }
        }
        destination_config = {
          destination_connection_profile_key = "bq-dest"
          bigquery_destination_config = {
            source_hierarchy_datasets = {
              dataset_template = {
                location          = "europe-west1"
                dataset_id_prefix = "ds"
                kms_key_name      = "projects/example-prj/locations/europe-west1/keyRings/example-kr/cryptoKeys/example-key"
              }
            }
            blmt_config = {
              bucket          = "example-bucket"
              connection_name = "example-prj.europe-west1.example-conn"
              file_format     = "PARQUET"
              table_format    = "ICEBERG"
              root_path       = "/"
            }
            append_only = true
          }
        }
        backfill_all = {
          postgresql_excluded_objects = {
            postgresql_schemas = {
              "staging" = { schema = "staging" }
            }
          }
        }
      }
      "mysql-to-gcs" = {
        stream_id    = "example-ds-stream-gcs"
        location     = "europe-west1"
        display_name = "Example MySQL to GCS"
        source_config = {
          source_connection_profile_key = "mysql-source"
          mysql_source_config = {
            max_concurrent_cdc_tasks = 5
            gtid                     = true
            include_objects = {
              mysql_databases = {
                "app" = {
                  database = "appdb"
                  mysql_tables = {
                    "orders" = {
                      table         = "orders"
                      mysql_columns = [{ column = "id", ordinal_position = 0 }]
                    }
                  }
                }
              }
            }
            exclude_objects = {
              mysql_databases = {
                "staging" = { database = "staging" }
              }
            }
          }
        }
        destination_config = {
          destination_connection_profile_key = "gcs-dest"
          gcs_destination_config = {
            path                   = "data"
            file_rotation_mb       = 200
            file_rotation_interval = "60s"
            json_file_format = {
              schema_file_format = "NO_SCHEMA_FILE"
              compression        = "GZIP"
            }
          }
        }
        backfill_none = true
      }
      "external-to-bq" = {
        stream_id    = "example-ds-stream-ext"
        location     = "europe-west1"
        display_name = "Example External Source to BigQuery"
        source_config = {
          source_connection_profile = "projects/example-prj/locations/europe-west1/connectionProfiles/example-ds-external"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
          }
        }
        destination_config = {
          destination_connection_profile_key = "bq-dest"
          bigquery_destination_config = {
            data_freshness = "900s"
            single_target_dataset = {
              dataset_id = "example-prj:example-dataset"
            }
          }
        }
        backfill_none = true
      }
    }
  }
}

run "rejects_two_engine_profiles" {
  command = plan

  variables {
    connection_profiles = {
      "bad" = {
        connection_profile_id = "example-ds-bad"
        display_name          = "Example Bad Profile"
        location              = "europe-west1"
        mysql_profile = {
          hostname = "example-mysql.example.internal"
          username = "datastream"
          password = "example-password"
        }
        gcs_profile = {
          bucket = "example-bucket"
        }
      }
    }
  }

  expect_failures = [var.connection_profiles]
}

run "rejects_both_bq_dataset_configs" {
  command = plan

  variables {
    connection_profiles = {
      "pg" = {
        connection_profile_id = "example-ds-pg"
        display_name          = "Example PostgreSQL Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
      }
      "bq" = {
        connection_profile_id = "example-ds-bq"
        display_name          = "Example BigQuery Destination"
        location              = "europe-west1"
        bigquery_profile      = true
      }
    }
    streams = {
      "bad" = {
        stream_id    = "example-ds-stream"
        location     = "europe-west1"
        display_name = "Example Stream"
        source_config = {
          source_connection_profile_key = "pg"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
          }
        }
        destination_config = {
          destination_connection_profile_key = "bq"
          bigquery_destination_config = {
            single_target_dataset = {
              dataset_id = "example-prj:example-dataset"
            }
            source_hierarchy_datasets = {
              dataset_template = { location = "europe-west1" }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.streams]
}

run "rejects_both_backfill_strategies" {
  command = plan

  variables {
    connection_profiles = {
      "pg" = {
        connection_profile_id = "example-ds-pg"
        display_name          = "Example PostgreSQL Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
      }
      "bq" = {
        connection_profile_id = "example-ds-bq"
        display_name          = "Example BigQuery Destination"
        location              = "europe-west1"
        bigquery_profile      = true
      }
    }
    streams = {
      "bad" = {
        stream_id    = "example-ds-stream"
        location     = "europe-west1"
        display_name = "Example Stream"
        source_config = {
          source_connection_profile_key = "pg"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
          }
        }
        destination_config = {
          destination_connection_profile_key = "bq"
          bigquery_destination_config = {
            single_target_dataset = {
              dataset_id = "example-prj:example-dataset"
            }
          }
        }
        backfill_all  = {}
        backfill_none = true
      }
    }
  }

  expect_failures = [var.streams]
}

run "rejects_missing_backfill_strategy" {
  command = plan

  variables {
    connection_profiles = {
      "pg" = {
        connection_profile_id = "example-ds-pg"
        display_name          = "Example PostgreSQL Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
      }
      "bq" = {
        connection_profile_id = "example-ds-bq"
        display_name          = "Example BigQuery Destination"
        location              = "europe-west1"
        bigquery_profile      = true
      }
    }
    streams = {
      "bad" = {
        stream_id    = "example-ds-stream"
        location     = "europe-west1"
        display_name = "Example Stream"
        source_config = {
          source_connection_profile_key = "pg"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
          }
        }
        destination_config = {
          destination_connection_profile_key = "bq"
          bigquery_destination_config = {
            single_target_dataset = {
              dataset_id = "example-prj:example-dataset"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.streams]
}

run "rejects_unknown_profile_key" {
  command = plan

  variables {
    connection_profiles = {
      "pg" = {
        connection_profile_id = "example-ds-pg"
        display_name          = "Example PostgreSQL Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
      }
    }
    streams = {
      "bad" = {
        stream_id    = "example-ds-stream"
        location     = "europe-west1"
        display_name = "Example Stream"
        source_config = {
          source_connection_profile_key = "nonexistent"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
          }
        }
        destination_config = {
          destination_connection_profile = "projects/example-prj/locations/europe-west1/connectionProfiles/example-ds-bq"
          bigquery_destination_config = {
            single_target_dataset = {
              dataset_id = "example-prj:example-dataset"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.streams]
}

run "rejects_bad_desired_state" {
  command = plan

  variables {
    connection_profiles = {
      "pg" = {
        connection_profile_id = "example-ds-pg"
        display_name          = "Example PostgreSQL Source"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
      }
      "bq" = {
        connection_profile_id = "example-ds-bq"
        display_name          = "Example BigQuery Destination"
        location              = "europe-west1"
        bigquery_profile      = true
      }
    }
    streams = {
      "bad" = {
        stream_id     = "example-ds-stream"
        location      = "europe-west1"
        display_name  = "Example Stream"
        desired_state = "STARTED"
        source_config = {
          source_connection_profile_key = "pg"
          postgresql_source_config = {
            replication_slot = "example_slot"
            publication      = "example_pub"
          }
        }
        destination_config = {
          destination_connection_profile_key = "bq"
          bigquery_destination_config = {
            single_target_dataset = {
              dataset_id = "example-prj:example-dataset"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.streams]
}

run "rejects_both_private_connection_configs" {
  command = plan

  variables {
    private_connections = {
      "bad" = {
        private_connection_id = "example-ds-connection"
        display_name          = "Example Private Connection"
        location              = "europe-west1"
        vpc_peering_config = {
          vpc    = "projects/example-prj/global/networks/example-net"
          subnet = "10.0.0.0/29"
        }
        psc_interface_config = {
          network_attachment = "projects/example-prj/regions/europe-west1/networkAttachments/example-att"
        }
      }
    }
  }

  expect_failures = [var.private_connections]
}

run "rejects_both_gcs_file_formats" {
  command = plan

  variables {
    connection_profiles = {
      "mysql" = {
        connection_profile_id = "example-ds-mysql"
        display_name          = "Example MySQL Source"
        location              = "europe-west1"
        mysql_profile = {
          hostname = "example-mysql.example.internal"
          username = "datastream"
          password = "example-password"
        }
      }
      "gcs" = {
        connection_profile_id = "example-ds-gcs"
        display_name          = "Example GCS Destination"
        location              = "europe-west1"
        gcs_profile = {
          bucket = "example-bucket"
        }
      }
    }
    streams = {
      "bad" = {
        stream_id    = "example-ds-stream"
        location     = "europe-west1"
        display_name = "Example Stream"
        source_config = {
          source_connection_profile_key = "mysql"
          mysql_source_config = {
            include_objects = {
              mysql_databases = {
                "app" = { database = "appdb" }
              }
            }
          }
        }
        destination_config = {
          destination_connection_profile_key = "gcs"
          gcs_destination_config = {
            avro_file_format = true
            json_file_format = {
              schema_file_format = "NO_SCHEMA_FILE"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.streams]
}

run "rejects_both_mongodb_connection_formats" {
  command = plan

  variables {
    connection_profiles = {
      "bad" = {
        connection_profile_id = "example-ds-mongo"
        display_name          = "Example MongoDB Source"
        location              = "europe-west1"
        mongodb_profile = {
          username                   = "datastream"
          host_addresses             = [{ hostname = "example-mongo.example.internal" }]
          password                   = "example-password"
          srv_connection_format      = true
          standard_connection_format = {}
        }
      }
    }
  }

  expect_failures = [var.connection_profiles]
}

run "rejects_both_mongodb_client_key_variants" {
  command = plan

  variables {
    connection_profiles = {
      "bad" = {
        connection_profile_id = "example-ds-mongo"
        display_name          = "Example MongoDB Source"
        location              = "europe-west1"
        mongodb_profile = {
          username                   = "datastream"
          host_addresses             = [{ hostname = "example-mongo.example.internal" }]
          password                   = "example-password"
          standard_connection_format = {}
          ssl_config = {
            client_key                       = "-----BEGIN PRIVATE KEY-----"
            client_certificate               = "-----BEGIN CERTIFICATE-----"
            ca_certificate                   = "-----BEGIN CERTIFICATE-----"
            secret_manager_stored_client_key = "projects/example-prj/secrets/example-secret/versions/1"
          }
        }
      }
    }
  }

  expect_failures = [var.connection_profiles]
}

run "rejects_both_connectivity_modes" {
  command = plan

  variables {
    private_connections = {
      "peering" = {
        private_connection_id = "example-ds-connection"
        display_name          = "Example Private Connection"
        location              = "europe-west1"
        vpc_peering_config = {
          vpc    = "projects/example-prj/global/networks/example-net"
          subnet = "10.0.0.0/29"
        }
      }
    }
    connection_profiles = {
      "bad" = {
        connection_profile_id = "example-ds-bad"
        display_name          = "Example Bad Profile"
        location              = "europe-west1"
        postgresql_profile = {
          hostname = "example-db.example.internal"
          username = "datastream"
          password = "example-password"
          database = "appdb"
        }
        forward_ssh_connectivity = {
          hostname = "example-bastion.example.internal"
          username = "tunnel"
        }
        private_connectivity = {
          private_connection_key = "peering"
        }
      }
    }
  }

  expect_failures = [var.connection_profiles]
}

run "rejects_empty_mysql_databases" {
  command = plan

  variables {
    connection_profiles = {
      "mysql" = {
        connection_profile_id = "example-ds-mysql"
        display_name          = "Example MySQL Source"
        location              = "europe-west1"
        mysql_profile = {
          hostname = "example-mysql.example.internal"
          username = "datastream"
          password = "example-password"
        }
      }
      "gcs" = {
        connection_profile_id = "example-ds-gcs"
        display_name          = "Example GCS Destination"
        location              = "europe-west1"
        gcs_profile = {
          bucket = "example-bucket"
        }
      }
    }
    streams = {
      "bad" = {
        stream_id    = "example-ds-stream"
        location     = "europe-west1"
        display_name = "Example Stream"
        source_config = {
          source_connection_profile_key = "mysql"
          mysql_source_config = {
            include_objects = {
              mysql_databases = {}
            }
          }
        }
        destination_config = {
          destination_connection_profile_key = "gcs"
          gcs_destination_config = {
            avro_file_format = true
          }
        }
      }
    }
  }

  expect_failures = [var.streams]
}
