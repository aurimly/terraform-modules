locals {
  source_profile_ids = {
    for k, s in var.streams : k => (
      s.source_config.source_connection_profile_key != null
      ? google_datastream_connection_profile.connection_profiles[s.source_config.source_connection_profile_key].id
      : s.source_config.source_connection_profile
    )
  }

  destination_profile_ids = {
    for k, s in var.streams : k => (
      s.destination_config.destination_connection_profile_key != null
      ? google_datastream_connection_profile.connection_profiles[s.destination_config.destination_connection_profile_key].id
      : s.destination_config.destination_connection_profile
    )
  }

  private_connection_ids = {
    for k, p in var.connection_profiles : k => (
      p.private_connectivity == null ? null : (
        p.private_connectivity.private_connection_key != null
        ? google_datastream_private_connection.private_connections[p.private_connectivity.private_connection_key].id
        : p.private_connectivity.private_connection
      )
    )
  }
}

resource "google_datastream_private_connection" "private_connections" {
  for_each = var.private_connections

  private_connection_id     = each.value.private_connection_id
  display_name              = each.value.display_name
  location                  = each.value.location
  project                   = each.value.project_id
  labels                    = each.value.labels
  deletion_policy           = each.value.deletion_policy
  create_without_validation = each.value.create_without_validation

  dynamic "vpc_peering_config" {
    for_each = each.value.vpc_peering_config != null ? [each.value.vpc_peering_config] : []

    content {
      vpc    = vpc_peering_config.value.vpc
      subnet = vpc_peering_config.value.subnet
    }
  }

  dynamic "psc_interface_config" {
    for_each = each.value.psc_interface_config != null ? [each.value.psc_interface_config] : []

    content {
      network_attachment = psc_interface_config.value.network_attachment
    }
  }
}

resource "google_datastream_connection_profile" "connection_profiles" {
  for_each = var.connection_profiles

  connection_profile_id     = each.value.connection_profile_id
  display_name              = each.value.display_name
  location                  = each.value.location
  project                   = each.value.project_id
  labels                    = each.value.labels
  deletion_policy           = each.value.deletion_policy
  create_without_validation = each.value.create_without_validation

  dynamic "oracle_profile" {
    for_each = each.value.oracle_profile != null ? [each.value.oracle_profile] : []

    content {
      hostname                       = oracle_profile.value.hostname
      port                           = oracle_profile.value.port
      username                       = oracle_profile.value.username
      password                       = oracle_profile.value.password
      secret_manager_stored_password = oracle_profile.value.secret_manager_stored_password
      database_service               = oracle_profile.value.database_service
      connection_attributes          = oracle_profile.value.connection_attributes
    }
  }

  dynamic "mysql_profile" {
    for_each = each.value.mysql_profile != null ? [each.value.mysql_profile] : []

    content {
      hostname                       = mysql_profile.value.hostname
      port                           = mysql_profile.value.port
      username                       = mysql_profile.value.username
      password                       = mysql_profile.value.password
      secret_manager_stored_password = mysql_profile.value.secret_manager_stored_password

      dynamic "ssl_config" {
        for_each = mysql_profile.value.ssl_config != null ? [mysql_profile.value.ssl_config] : []

        content {
          client_key         = ssl_config.value.client_key
          client_certificate = ssl_config.value.client_certificate
          ca_certificate     = ssl_config.value.ca_certificate
        }
      }
    }
  }

  dynamic "postgresql_profile" {
    for_each = each.value.postgresql_profile != null ? [each.value.postgresql_profile] : []

    content {
      hostname                       = postgresql_profile.value.hostname
      port                           = postgresql_profile.value.port
      username                       = postgresql_profile.value.username
      password                       = postgresql_profile.value.password
      secret_manager_stored_password = postgresql_profile.value.secret_manager_stored_password
      database                       = postgresql_profile.value.database

      dynamic "ssl_config" {
        for_each = postgresql_profile.value.ssl_config != null ? [postgresql_profile.value.ssl_config] : []

        content {
          dynamic "server_verification" {
            for_each = ssl_config.value.server_verification != null ? [ssl_config.value.server_verification] : []

            content {
              ca_certificate = server_verification.value.ca_certificate
            }
          }

          dynamic "server_and_client_verification" {
            for_each = ssl_config.value.server_and_client_verification != null ? [ssl_config.value.server_and_client_verification] : []

            content {
              client_certificate = server_and_client_verification.value.client_certificate
              client_key         = server_and_client_verification.value.client_key
              ca_certificate     = server_and_client_verification.value.ca_certificate
            }
          }
        }
      }
    }
  }

  dynamic "sql_server_profile" {
    for_each = each.value.sql_server_profile != null ? [each.value.sql_server_profile] : []

    content {
      hostname                       = sql_server_profile.value.hostname
      port                           = sql_server_profile.value.port
      username                       = sql_server_profile.value.username
      password                       = sql_server_profile.value.password
      secret_manager_stored_password = sql_server_profile.value.secret_manager_stored_password
      database                       = sql_server_profile.value.database
    }
  }

  dynamic "mongodb_profile" {
    for_each = each.value.mongodb_profile != null ? [each.value.mongodb_profile] : []

    content {
      replica_set                    = mongodb_profile.value.replica_set
      username                       = mongodb_profile.value.username
      password                       = mongodb_profile.value.password
      secret_manager_stored_password = mongodb_profile.value.secret_manager_stored_password
      additional_options             = mongodb_profile.value.additional_options

      dynamic "host_addresses" {
        for_each = mongodb_profile.value.host_addresses

        content {
          hostname = host_addresses.value.hostname
          port     = host_addresses.value.port
        }
      }

      dynamic "ssl_config" {
        for_each = mongodb_profile.value.ssl_config != null ? [mongodb_profile.value.ssl_config] : []

        content {
          client_key                       = ssl_config.value.client_key
          client_certificate               = ssl_config.value.client_certificate
          ca_certificate                   = ssl_config.value.ca_certificate
          secret_manager_stored_client_key = ssl_config.value.secret_manager_stored_client_key
        }
      }

      dynamic "srv_connection_format" {
        for_each = mongodb_profile.value.srv_connection_format == true ? [1] : []

        content {}
      }

      dynamic "standard_connection_format" {
        for_each = mongodb_profile.value.standard_connection_format != null ? [mongodb_profile.value.standard_connection_format] : []

        content {
          direct_connection = standard_connection_format.value.direct_connection
        }
      }
    }
  }

  dynamic "gcs_profile" {
    for_each = each.value.gcs_profile != null ? [each.value.gcs_profile] : []

    content {
      bucket    = gcs_profile.value.bucket
      root_path = gcs_profile.value.root_path
    }
  }

  dynamic "bigquery_profile" {
    for_each = each.value.bigquery_profile == true ? [1] : []

    content {}
  }

  dynamic "forward_ssh_connectivity" {
    for_each = each.value.forward_ssh_connectivity != null ? [each.value.forward_ssh_connectivity] : []

    content {
      hostname    = forward_ssh_connectivity.value.hostname
      username    = forward_ssh_connectivity.value.username
      port        = forward_ssh_connectivity.value.port
      password    = forward_ssh_connectivity.value.password
      private_key = forward_ssh_connectivity.value.private_key
    }
  }

  dynamic "private_connectivity" {
    for_each = each.value.private_connectivity != null ? [1] : []

    content {
      private_connection = local.private_connection_ids[each.key]
    }
  }

  depends_on = [google_datastream_private_connection.private_connections]
}

resource "google_datastream_stream" "streams" {
  for_each = var.streams

  stream_id                       = each.value.stream_id
  location                        = each.value.location
  display_name                    = each.value.display_name
  project                         = each.value.project_id
  labels                          = each.value.labels
  desired_state                   = each.value.desired_state
  customer_managed_encryption_key = each.value.customer_managed_encryption_key
  create_without_validation       = each.value.create_without_validation
  deletion_policy                 = each.value.deletion_policy

  source_config {
    source_connection_profile = local.source_profile_ids[each.key]

    dynamic "mysql_source_config" {
      for_each = each.value.source_config.mysql_source_config != null ? [each.value.source_config.mysql_source_config] : []

      content {
        max_concurrent_cdc_tasks      = mysql_source_config.value.max_concurrent_cdc_tasks
        max_concurrent_backfill_tasks = mysql_source_config.value.max_concurrent_backfill_tasks

        dynamic "include_objects" {
          for_each = mysql_source_config.value.include_objects != null ? [1] : []

          content {
            dynamic "mysql_databases" {
              for_each = mysql_source_config.value.include_objects.mysql_databases

              content {
                database = mysql_databases.value.database

                dynamic "mysql_tables" {
                  for_each = mysql_databases.value.mysql_tables

                  content {
                    table = mysql_tables.value.table

                    dynamic "mysql_columns" {
                      for_each = mysql_tables.value.mysql_columns != null ? mysql_tables.value.mysql_columns : []

                      content {
                        column           = mysql_columns.value.column
                        data_type        = mysql_columns.value.data_type
                        collation        = mysql_columns.value.collation
                        primary_key      = mysql_columns.value.primary_key
                        nullable         = mysql_columns.value.nullable
                        ordinal_position = mysql_columns.value.ordinal_position
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "exclude_objects" {
          for_each = mysql_source_config.value.exclude_objects != null ? [1] : []

          content {
            dynamic "mysql_databases" {
              for_each = mysql_source_config.value.exclude_objects.mysql_databases

              content {
                database = mysql_databases.value.database

                dynamic "mysql_tables" {
                  for_each = mysql_databases.value.mysql_tables

                  content {
                    table = mysql_tables.value.table

                    dynamic "mysql_columns" {
                      for_each = mysql_tables.value.mysql_columns != null ? mysql_tables.value.mysql_columns : []

                      content {
                        column           = mysql_columns.value.column
                        data_type        = mysql_columns.value.data_type
                        collation        = mysql_columns.value.collation
                        primary_key      = mysql_columns.value.primary_key
                        nullable         = mysql_columns.value.nullable
                        ordinal_position = mysql_columns.value.ordinal_position
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "binary_log_position" {
          for_each = mysql_source_config.value.binary_log_position == true ? [1] : []

          content {}
        }

        dynamic "gtid" {
          for_each = mysql_source_config.value.gtid == true ? [1] : []

          content {}
        }
      }
    }

    dynamic "postgresql_source_config" {
      for_each = each.value.source_config.postgresql_source_config != null ? [each.value.source_config.postgresql_source_config] : []

      content {
        replication_slot              = postgresql_source_config.value.replication_slot
        publication                   = postgresql_source_config.value.publication
        max_concurrent_backfill_tasks = postgresql_source_config.value.max_concurrent_backfill_tasks

        dynamic "include_objects" {
          for_each = postgresql_source_config.value.include_objects != null ? [1] : []

          content {
            dynamic "postgresql_schemas" {
              for_each = postgresql_source_config.value.include_objects.postgresql_schemas

              content {
                schema = postgresql_schemas.value.schema

                dynamic "postgresql_tables" {
                  for_each = postgresql_schemas.value.postgresql_tables

                  content {
                    table = postgresql_tables.value.table

                    dynamic "postgresql_columns" {
                      for_each = postgresql_tables.value.postgresql_columns != null ? postgresql_tables.value.postgresql_columns : []

                      content {
                        column           = postgresql_columns.value.column
                        data_type        = postgresql_columns.value.data_type
                        primary_key      = postgresql_columns.value.primary_key
                        nullable         = postgresql_columns.value.nullable
                        ordinal_position = postgresql_columns.value.ordinal_position
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "exclude_objects" {
          for_each = postgresql_source_config.value.exclude_objects != null ? [1] : []

          content {
            dynamic "postgresql_schemas" {
              for_each = postgresql_source_config.value.exclude_objects.postgresql_schemas

              content {
                schema = postgresql_schemas.value.schema

                dynamic "postgresql_tables" {
                  for_each = postgresql_schemas.value.postgresql_tables

                  content {
                    table = postgresql_tables.value.table

                    dynamic "postgresql_columns" {
                      for_each = postgresql_tables.value.postgresql_columns != null ? postgresql_tables.value.postgresql_columns : []

                      content {
                        column           = postgresql_columns.value.column
                        data_type        = postgresql_columns.value.data_type
                        primary_key      = postgresql_columns.value.primary_key
                        nullable         = postgresql_columns.value.nullable
                        ordinal_position = postgresql_columns.value.ordinal_position
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    dynamic "oracle_source_config" {
      for_each = each.value.source_config.oracle_source_config != null ? [each.value.source_config.oracle_source_config] : []

      content {
        max_concurrent_cdc_tasks      = oracle_source_config.value.max_concurrent_cdc_tasks
        max_concurrent_backfill_tasks = oracle_source_config.value.max_concurrent_backfill_tasks

        dynamic "include_objects" {
          for_each = oracle_source_config.value.include_objects != null ? [1] : []

          content {
            dynamic "oracle_schemas" {
              for_each = oracle_source_config.value.include_objects.oracle_schemas

              content {
                schema = oracle_schemas.value.schema

                dynamic "oracle_tables" {
                  for_each = oracle_schemas.value.oracle_tables

                  content {
                    table = oracle_tables.value.table

                    dynamic "oracle_columns" {
                      for_each = oracle_tables.value.oracle_columns != null ? oracle_tables.value.oracle_columns : []

                      content {
                        column    = oracle_columns.value.column
                        data_type = oracle_columns.value.data_type
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "exclude_objects" {
          for_each = oracle_source_config.value.exclude_objects != null ? [1] : []

          content {
            dynamic "oracle_schemas" {
              for_each = oracle_source_config.value.exclude_objects.oracle_schemas

              content {
                schema = oracle_schemas.value.schema

                dynamic "oracle_tables" {
                  for_each = oracle_schemas.value.oracle_tables

                  content {
                    table = oracle_tables.value.table

                    dynamic "oracle_columns" {
                      for_each = oracle_tables.value.oracle_columns != null ? oracle_tables.value.oracle_columns : []

                      content {
                        column    = oracle_columns.value.column
                        data_type = oracle_columns.value.data_type
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "drop_large_objects" {
          for_each = oracle_source_config.value.drop_large_objects == true ? [1] : []

          content {}
        }

        dynamic "stream_large_objects" {
          for_each = oracle_source_config.value.stream_large_objects == true ? [1] : []

          content {}
        }
      }
    }

    dynamic "sql_server_source_config" {
      for_each = each.value.source_config.sql_server_source_config != null ? [each.value.source_config.sql_server_source_config] : []

      content {
        max_concurrent_cdc_tasks      = sql_server_source_config.value.max_concurrent_cdc_tasks
        max_concurrent_backfill_tasks = sql_server_source_config.value.max_concurrent_backfill_tasks

        dynamic "include_objects" {
          for_each = sql_server_source_config.value.include_objects != null ? [1] : []

          content {
            dynamic "schemas" {
              for_each = sql_server_source_config.value.include_objects.schemas

              content {
                schema = schemas.value.schema

                dynamic "tables" {
                  for_each = schemas.value.tables

                  content {
                    table = tables.value.table

                    dynamic "columns" {
                      for_each = tables.value.columns != null ? tables.value.columns : []

                      content {
                        column    = columns.value.column
                        data_type = columns.value.data_type
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "exclude_objects" {
          for_each = sql_server_source_config.value.exclude_objects != null ? [1] : []

          content {
            dynamic "schemas" {
              for_each = sql_server_source_config.value.exclude_objects.schemas

              content {
                schema = schemas.value.schema

                dynamic "tables" {
                  for_each = schemas.value.tables

                  content {
                    table = tables.value.table

                    dynamic "columns" {
                      for_each = tables.value.columns != null ? tables.value.columns : []

                      content {
                        column    = columns.value.column
                        data_type = columns.value.data_type
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "transaction_logs" {
          for_each = sql_server_source_config.value.transaction_logs == true ? [1] : []

          content {}
        }

        dynamic "change_tables" {
          for_each = sql_server_source_config.value.change_tables == true ? [1] : []

          content {}
        }
      }
    }

    dynamic "salesforce_source_config" {
      for_each = each.value.source_config.salesforce_source_config != null ? [each.value.source_config.salesforce_source_config] : []

      content {
        polling_interval = salesforce_source_config.value.polling_interval

        dynamic "include_objects" {
          for_each = salesforce_source_config.value.include_objects != null ? [1] : []

          content {
            dynamic "objects" {
              for_each = salesforce_source_config.value.include_objects.objects

              content {
                object_name = objects.value.object_name

                dynamic "fields" {
                  for_each = objects.value.fields != null ? objects.value.fields : []

                  content {
                    name = fields.value.name
                  }
                }
              }
            }
          }
        }

        dynamic "exclude_objects" {
          for_each = salesforce_source_config.value.exclude_objects != null ? [1] : []

          content {
            dynamic "objects" {
              for_each = salesforce_source_config.value.exclude_objects.objects

              content {
                object_name = objects.value.object_name

                dynamic "fields" {
                  for_each = objects.value.fields != null ? objects.value.fields : []

                  content {
                    name = fields.value.name
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = local.destination_profile_ids[each.key]

    dynamic "gcs_destination_config" {
      for_each = each.value.destination_config.gcs_destination_config != null ? [each.value.destination_config.gcs_destination_config] : []

      content {
        path                   = gcs_destination_config.value.path
        file_rotation_mb       = gcs_destination_config.value.file_rotation_mb
        file_rotation_interval = gcs_destination_config.value.file_rotation_interval

        dynamic "avro_file_format" {
          for_each = gcs_destination_config.value.avro_file_format == true ? [1] : []

          content {}
        }

        dynamic "json_file_format" {
          for_each = gcs_destination_config.value.json_file_format != null ? [gcs_destination_config.value.json_file_format] : []

          content {
            schema_file_format = json_file_format.value.schema_file_format
            compression        = json_file_format.value.compression
          }
        }
      }
    }

    dynamic "bigquery_destination_config" {
      for_each = each.value.destination_config.bigquery_destination_config != null ? [each.value.destination_config.bigquery_destination_config] : []

      content {
        data_freshness = bigquery_destination_config.value.data_freshness

        dynamic "single_target_dataset" {
          for_each = bigquery_destination_config.value.single_target_dataset != null ? [bigquery_destination_config.value.single_target_dataset] : []

          content {
            dataset_id = single_target_dataset.value.dataset_id
          }
        }

        dynamic "source_hierarchy_datasets" {
          for_each = bigquery_destination_config.value.source_hierarchy_datasets != null ? [bigquery_destination_config.value.source_hierarchy_datasets] : []

          content {
            project_id = source_hierarchy_datasets.value.project_id

            dynamic "dataset_template" {
              for_each = [source_hierarchy_datasets.value.dataset_template]

              content {
                location          = dataset_template.value.location
                dataset_id_prefix = dataset_template.value.dataset_id_prefix
                kms_key_name      = dataset_template.value.kms_key_name
              }
            }
          }
        }

        dynamic "blmt_config" {
          for_each = bigquery_destination_config.value.blmt_config != null ? [bigquery_destination_config.value.blmt_config] : []

          content {
            bucket          = blmt_config.value.bucket
            connection_name = blmt_config.value.connection_name
            file_format     = blmt_config.value.file_format
            table_format    = blmt_config.value.table_format
            root_path       = blmt_config.value.root_path
          }
        }

        dynamic "merge" {
          for_each = bigquery_destination_config.value.merge == true ? [1] : []

          content {}
        }

        dynamic "append_only" {
          for_each = bigquery_destination_config.value.append_only == true ? [1] : []

          content {}
        }
      }
    }
  }

  dynamic "backfill_all" {
    for_each = each.value.backfill_all != null ? [each.value.backfill_all] : []

    content {
      dynamic "mysql_excluded_objects" {
        for_each = backfill_all.value.mysql_excluded_objects != null ? [1] : []

        content {
          dynamic "mysql_databases" {
            for_each = backfill_all.value.mysql_excluded_objects.mysql_databases

            content {
              database = mysql_databases.value.database

              dynamic "mysql_tables" {
                for_each = mysql_databases.value.mysql_tables

                content {
                  table = mysql_tables.value.table

                  dynamic "mysql_columns" {
                    for_each = mysql_tables.value.mysql_columns != null ? mysql_tables.value.mysql_columns : []

                    content {
                      column           = mysql_columns.value.column
                      data_type        = mysql_columns.value.data_type
                      collation        = mysql_columns.value.collation
                      primary_key      = mysql_columns.value.primary_key
                      nullable         = mysql_columns.value.nullable
                      ordinal_position = mysql_columns.value.ordinal_position
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "postgresql_excluded_objects" {
        for_each = backfill_all.value.postgresql_excluded_objects != null ? [1] : []

        content {
          dynamic "postgresql_schemas" {
            for_each = backfill_all.value.postgresql_excluded_objects.postgresql_schemas

            content {
              schema = postgresql_schemas.value.schema

              dynamic "postgresql_tables" {
                for_each = postgresql_schemas.value.postgresql_tables

                content {
                  table = postgresql_tables.value.table

                  dynamic "postgresql_columns" {
                    for_each = postgresql_tables.value.postgresql_columns != null ? postgresql_tables.value.postgresql_columns : []

                    content {
                      column           = postgresql_columns.value.column
                      data_type        = postgresql_columns.value.data_type
                      primary_key      = postgresql_columns.value.primary_key
                      nullable         = postgresql_columns.value.nullable
                      ordinal_position = postgresql_columns.value.ordinal_position
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "oracle_excluded_objects" {
        for_each = backfill_all.value.oracle_excluded_objects != null ? [1] : []

        content {
          dynamic "oracle_schemas" {
            for_each = backfill_all.value.oracle_excluded_objects.oracle_schemas

            content {
              schema = oracle_schemas.value.schema

              dynamic "oracle_tables" {
                for_each = oracle_schemas.value.oracle_tables

                content {
                  table = oracle_tables.value.table

                  dynamic "oracle_columns" {
                    for_each = oracle_tables.value.oracle_columns != null ? oracle_tables.value.oracle_columns : []

                    content {
                      column    = oracle_columns.value.column
                      data_type = oracle_columns.value.data_type
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "sql_server_excluded_objects" {
        for_each = backfill_all.value.sql_server_excluded_objects != null ? [1] : []

        content {
          dynamic "schemas" {
            for_each = backfill_all.value.sql_server_excluded_objects.schemas

            content {
              schema = schemas.value.schema

              dynamic "tables" {
                for_each = schemas.value.tables

                content {
                  table = tables.value.table

                  dynamic "columns" {
                    for_each = tables.value.columns != null ? tables.value.columns : []

                    content {
                      column    = columns.value.column
                      data_type = columns.value.data_type
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "salesforce_excluded_objects" {
        for_each = backfill_all.value.salesforce_excluded_objects != null ? [1] : []

        content {
          dynamic "objects" {
            for_each = backfill_all.value.salesforce_excluded_objects.objects

            content {
              object_name = objects.value.object_name

              dynamic "fields" {
                for_each = objects.value.fields != null ? objects.value.fields : []

                content {
                  name = fields.value.name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "backfill_none" {
    for_each = each.value.backfill_none == true ? [1] : []

    content {}
  }

  depends_on = [
    google_datastream_connection_profile.connection_profiles,
    google_datastream_private_connection.private_connections,
  ]
}
