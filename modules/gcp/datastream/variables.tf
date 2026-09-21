variable "private_connections" {
  description = "Map of Datastream private connections keyed by an arbitrary identifier. Each entry creates one google_datastream_private_connection."
  type = map(object({
    private_connection_id     = string
    display_name              = string
    location                  = string
    project_id                = optional(string)
    labels                    = optional(map(string), {})
    deletion_policy           = optional(string)
    create_without_validation = optional(bool)
    vpc_peering_config = optional(object({
      vpc    = string
      subnet = string
    }))
    psc_interface_config = optional(object({
      network_attachment = string
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, c in var.private_connections : can(regex("^[a-z][-a-z0-9]{0,62}[a-z0-9]$", c.private_connection_id))])
    error_message = "private_connection_id must be 2-63 characters, start with a lowercase letter, end with a lowercase letter or digit, and contain only hyphens, lowercase letters and digits."
  }

  validation {
    condition     = alltrue([for k, c in var.private_connections : c.deletion_policy == null || contains(["DEFAULT", "FORCE", "PREVENT", "ABANDON"], c.deletion_policy)])
    error_message = "deletion_policy must be one of DEFAULT, FORCE, PREVENT or ABANDON (case-sensitive; defaults to FORCE server-side, which also deletes child routes)."
  }

  validation {
    condition = alltrue([
      for k, c in var.private_connections :
      sum([for f in [c.vpc_peering_config != null, c.psc_interface_config != null] : f ? 1 : 0]) == 1
    ])
    error_message = "each private connection requires exactly one of vpc_peering_config or psc_interface_config."
  }

  validation {
    condition     = alltrue([for k, c in var.private_connections : c.vpc_peering_config == null || can(cidrnetmask(c.vpc_peering_config.subnet)) && split("/", c.vpc_peering_config.subnet)[1] == "29"])
    error_message = "vpc_peering_config.subnet must be a CIDR with a /29 mask."
  }
}

variable "connection_profiles" {
  description = "Map of Datastream connection profiles keyed by an arbitrary identifier. Each entry creates one google_datastream_connection_profile; exactly one engine profile block per entry (validated)."
  type = map(object({
    connection_profile_id     = string
    display_name              = string
    location                  = string
    project_id                = optional(string)
    labels                    = optional(map(string), {})
    deletion_policy           = optional(string)
    create_without_validation = optional(bool)
    oracle_profile = optional(object({
      hostname                       = string
      username                       = string
      database_service               = string
      port                           = optional(number)
      password                       = optional(string)
      secret_manager_stored_password = optional(string)
      connection_attributes          = optional(map(string))
    }))
    mysql_profile = optional(object({
      hostname                       = string
      username                       = string
      port                           = optional(number)
      password                       = optional(string)
      secret_manager_stored_password = optional(string)
      ssl_config = optional(object({
        client_key         = optional(string)
        client_certificate = optional(string)
        ca_certificate     = optional(string)
      }))
    }))
    postgresql_profile = optional(object({
      hostname                       = string
      username                       = string
      database                       = string
      port                           = optional(number)
      password                       = optional(string)
      secret_manager_stored_password = optional(string)
      ssl_config = optional(object({
        server_verification = optional(object({
          ca_certificate = string
        }))
        server_and_client_verification = optional(object({
          client_certificate = string
          client_key         = string
          ca_certificate     = string
        }))
      }))
    }))
    sql_server_profile = optional(object({
      hostname                       = string
      username                       = string
      database                       = string
      port                           = optional(number)
      password                       = optional(string)
      secret_manager_stored_password = optional(string)
    }))
    mongodb_profile = optional(object({
      username = string
      host_addresses = list(object({
        hostname = string
        port     = optional(number)
      }))
      replica_set                    = optional(string)
      password                       = optional(string)
      secret_manager_stored_password = optional(string)
      additional_options             = optional(map(string))
      ssl_config = optional(object({
        client_key                       = optional(string)
        client_certificate               = optional(string)
        ca_certificate                   = optional(string)
        secret_manager_stored_client_key = optional(string)
      }))
      srv_connection_format      = optional(bool)
      standard_connection_format = optional(object({ direct_connection = optional(bool) }))
    }))
    gcs_profile = optional(object({
      bucket    = string
      root_path = optional(string)
    }))
    bigquery_profile = optional(bool)
    forward_ssh_connectivity = optional(object({
      hostname    = string
      username    = string
      port        = optional(number)
      password    = optional(string)
      private_key = optional(string)
    }))
    private_connectivity = optional(object({
      private_connection_key = optional(string)
      private_connection     = optional(string)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, p in var.connection_profiles : can(regex("^[a-z][-a-z0-9]{0,62}[a-z0-9]$", p.connection_profile_id))])
    error_message = "connection_profile_id must be 2-63 characters, start with a lowercase letter, end with a lowercase letter or digit, and contain only hyphens, lowercase letters and digits."
  }

  validation {
    condition     = alltrue([for k, p in var.connection_profiles : p.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], p.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive; defaults to DELETE)."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      sum([for f in [
        p.oracle_profile != null,
        p.mysql_profile != null,
        p.postgresql_profile != null,
        p.sql_server_profile != null,
        p.mongodb_profile != null,
        p.gcs_profile != null,
        p.bigquery_profile == true,
      ] : f ? 1 : 0]) == 1
    ])
    error_message = "each connection profile requires exactly one engine profile block: oracle_profile, mysql_profile, postgresql_profile, sql_server_profile, mongodb_profile, gcs_profile or bigquery_profile (salesforce_profile and spanner_profile are google-beta only and not modeled by this module)."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.oracle_profile == null || (p.oracle_profile.password == null) != (p.oracle_profile.secret_manager_stored_password == null)
    ])
    error_message = "oracle_profile requires exactly one of password or secret_manager_stored_password."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.mysql_profile == null || (p.mysql_profile.password == null) != (p.mysql_profile.secret_manager_stored_password == null)
    ])
    error_message = "mysql_profile requires exactly one of password or secret_manager_stored_password."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.mysql_profile == null || p.mysql_profile.ssl_config == null || alltrue([
        for s in [p.mysql_profile.ssl_config] :
        (s.client_key != null) == (s.client_certificate != null) && (s.client_key != null) == (s.ca_certificate != null)
      ])
    ])
    error_message = "mysql_profile.ssl_config requires all three of client_key, client_certificate and ca_certificate together (all-or-nothing)."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.postgresql_profile == null || (p.postgresql_profile.password == null) != (p.postgresql_profile.secret_manager_stored_password == null)
    ])
    error_message = "postgresql_profile requires exactly one of password or secret_manager_stored_password."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.postgresql_profile == null || p.postgresql_profile.ssl_config == null ||
      sum([for f in [
        p.postgresql_profile.ssl_config.server_verification != null,
        p.postgresql_profile.ssl_config.server_and_client_verification != null,
      ] : f ? 1 : 0]) <= 1
    ])
    error_message = "postgresql_profile.ssl_config accepts at most one of server_verification or server_and_client_verification."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.sql_server_profile == null || (p.sql_server_profile.password == null) != (p.sql_server_profile.secret_manager_stored_password == null)
    ])
    error_message = "sql_server_profile requires exactly one of password or secret_manager_stored_password."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.mongodb_profile == null || (p.mongodb_profile.password == null) != (p.mongodb_profile.secret_manager_stored_password == null)
    ])
    error_message = "mongodb_profile requires exactly one of password or secret_manager_stored_password."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.mongodb_profile == null ||
      sum([for f in [p.mongodb_profile.srv_connection_format == true, p.mongodb_profile.standard_connection_format != null] : f ? 1 : 0]) == 1
    ])
    error_message = "mongodb_profile requires exactly one of srv_connection_format = true or standard_connection_format."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.mongodb_profile == null || p.mongodb_profile.ssl_config == null || p.mongodb_profile.ssl_config.client_key == null || p.mongodb_profile.ssl_config.secret_manager_stored_client_key == null
    ])
    error_message = "mongodb_profile.ssl_config accepts at most one of client_key or secret_manager_stored_client_key."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.mongodb_profile == null || p.mongodb_profile.ssl_config == null || p.mongodb_profile.ssl_config.secret_manager_stored_client_key != null || alltrue([
        for s in [p.mongodb_profile.ssl_config] :
        (s.client_key != null) == (s.client_certificate != null) && (s.client_key != null) == (s.ca_certificate != null)
      ])
    ])
    error_message = "mongodb_profile.ssl_config requires all three of client_key, client_certificate and ca_certificate together when client_key is used (all-or-nothing)."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      sum([for f in [p.forward_ssh_connectivity != null, p.private_connectivity != null] : f ? 1 : 0]) <= 1
    ])
    error_message = "at most one of forward_ssh_connectivity or private_connectivity per connection profile."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.private_connectivity == null ||
      sum([for f in [p.private_connectivity.private_connection_key != null, p.private_connectivity.private_connection != null] : f ? 1 : 0]) == 1
    ])
    error_message = "private_connectivity requires exactly one of private_connection_key (a key into var.private_connections) or private_connection (a full resource ID)."
  }

  validation {
    condition = alltrue([
      for k, p in var.connection_profiles :
      p.private_connectivity == null || p.private_connectivity.private_connection_key == null ||
      contains(keys(var.private_connections), p.private_connectivity.private_connection_key)
    ])
    error_message = "private_connectivity.private_connection_key must be a key of var.private_connections."
  }
}

variable "streams" {
  description = "Map of Datastream streams keyed by an arbitrary identifier. Each entry creates one google_datastream_stream. Source/destination connection profiles are referenced by key into var.connection_profiles or by full resource ID (exactly one, validated)."
  type = map(object({
    stream_id                       = string
    location                        = string
    display_name                    = string
    project_id                      = optional(string)
    labels                          = optional(map(string), {})
    desired_state                   = optional(string)
    customer_managed_encryption_key = optional(string)
    create_without_validation       = optional(bool)
    deletion_policy                 = optional(string)

    source_config = object({
      source_connection_profile_key = optional(string)
      source_connection_profile     = optional(string)

      mysql_source_config = optional(object({
        max_concurrent_cdc_tasks      = optional(number)
        max_concurrent_backfill_tasks = optional(number)
        binary_log_position           = optional(bool)
        gtid                          = optional(bool)
        include_objects = optional(object({
          mysql_databases = map(object({
            database = string
            mysql_tables = optional(map(object({
              table = string
              mysql_columns = optional(list(object({
                column           = optional(string)
                data_type        = optional(string)
                collation        = optional(string)
                primary_key      = optional(bool)
                nullable         = optional(bool)
                ordinal_position = optional(number)
              })))
            })), {})
          }))
        }))
        exclude_objects = optional(object({
          mysql_databases = map(object({
            database = string
            mysql_tables = optional(map(object({
              table = string
              mysql_columns = optional(list(object({
                column           = optional(string)
                data_type        = optional(string)
                collation        = optional(string)
                primary_key      = optional(bool)
                nullable         = optional(bool)
                ordinal_position = optional(number)
              })))
            })), {})
          }))
        }))
      }))

      postgresql_source_config = optional(object({
        replication_slot              = string
        publication                   = string
        max_concurrent_backfill_tasks = optional(number)
        include_objects = optional(object({
          postgresql_schemas = map(object({
            schema = string
            postgresql_tables = optional(map(object({
              table = string
              postgresql_columns = optional(list(object({
                column           = optional(string)
                data_type        = optional(string)
                primary_key      = optional(bool)
                nullable         = optional(bool)
                ordinal_position = optional(number)
              })))
            })), {})
          }))
        }))
        exclude_objects = optional(object({
          postgresql_schemas = map(object({
            schema = string
            postgresql_tables = optional(map(object({
              table = string
              postgresql_columns = optional(list(object({
                column           = optional(string)
                data_type        = optional(string)
                primary_key      = optional(bool)
                nullable         = optional(bool)
                ordinal_position = optional(number)
              })))
            })), {})
          }))
        }))
      }))

      oracle_source_config = optional(object({
        max_concurrent_cdc_tasks      = optional(number)
        max_concurrent_backfill_tasks = optional(number)
        drop_large_objects            = optional(bool)
        stream_large_objects          = optional(bool)
        include_objects = optional(object({
          oracle_schemas = map(object({
            schema = string
            oracle_tables = optional(map(object({
              table = string
              oracle_columns = optional(list(object({
                column    = optional(string)
                data_type = optional(string)
              })))
            })), {})
          }))
        }))
        exclude_objects = optional(object({
          oracle_schemas = map(object({
            schema = string
            oracle_tables = optional(map(object({
              table = string
              oracle_columns = optional(list(object({
                column    = optional(string)
                data_type = optional(string)
              })))
            })), {})
          }))
        }))
      }))

      sql_server_source_config = optional(object({
        max_concurrent_cdc_tasks      = optional(number)
        max_concurrent_backfill_tasks = optional(number)
        transaction_logs              = optional(bool)
        change_tables                 = optional(bool)
        include_objects = optional(object({
          schemas = map(object({
            schema = string
            tables = optional(map(object({
              table = string
              columns = optional(list(object({
                column    = optional(string)
                data_type = optional(string)
              })))
            })), {})
          }))
        }))
        exclude_objects = optional(object({
          schemas = map(object({
            schema = string
            tables = optional(map(object({
              table = string
              columns = optional(list(object({
                column    = optional(string)
                data_type = optional(string)
              })))
            })), {})
          }))
        }))
      }))

      salesforce_source_config = optional(object({
        polling_interval = string
        include_objects = optional(object({
          objects = map(object({
            object_name = optional(string)
            fields      = optional(list(object({ name = optional(string) })))
          }))
        }))
        exclude_objects = optional(object({
          objects = map(object({
            object_name = optional(string)
            fields      = optional(list(object({ name = optional(string) })))
          }))
        }))
      }))
    })

    destination_config = object({
      destination_connection_profile_key = optional(string)
      destination_connection_profile     = optional(string)

      gcs_destination_config = optional(object({
        path                   = optional(string)
        file_rotation_mb       = optional(number)
        file_rotation_interval = optional(string)
        avro_file_format       = optional(bool)
        json_file_format = optional(object({
          schema_file_format = optional(string)
          compression        = optional(string)
        }))
      }))

      bigquery_destination_config = optional(object({
        data_freshness = optional(string)
        single_target_dataset = optional(object({
          dataset_id = string
        }))
        source_hierarchy_datasets = optional(object({
          project_id = optional(string)
          dataset_template = object({
            location          = string
            dataset_id_prefix = optional(string)
            kms_key_name      = optional(string)
          })
        }))
        blmt_config = optional(object({
          bucket          = string
          connection_name = string
          file_format     = string
          table_format    = string
          root_path       = optional(string)
        }))
        merge       = optional(bool)
        append_only = optional(bool)
      }))
    })

    backfill_all = optional(object({
      mysql_excluded_objects = optional(object({
        mysql_databases = map(object({
          database = string
          mysql_tables = optional(map(object({
            table = string
            mysql_columns = optional(list(object({
              column           = optional(string)
              data_type        = optional(string)
              collation        = optional(string)
              primary_key      = optional(bool)
              nullable         = optional(bool)
              ordinal_position = optional(number)
            })))
          })), {})
        }))
      }))
      postgresql_excluded_objects = optional(object({
        postgresql_schemas = map(object({
          schema = string
          postgresql_tables = optional(map(object({
            table = string
            postgresql_columns = optional(list(object({
              column           = optional(string)
              data_type        = optional(string)
              primary_key      = optional(bool)
              nullable         = optional(bool)
              ordinal_position = optional(number)
            })))
          })), {})
        }))
      }))
      oracle_excluded_objects = optional(object({
        oracle_schemas = map(object({
          schema = string
          oracle_tables = optional(map(object({
            table = string
            oracle_columns = optional(list(object({
              column    = optional(string)
              data_type = optional(string)
            })))
          })), {})
        }))
      }))
      sql_server_excluded_objects = optional(object({
        schemas = map(object({
          schema = string
          tables = optional(map(object({
            table = string
            columns = optional(list(object({
              column    = optional(string)
              data_type = optional(string)
            })))
          })), {})
        }))
      }))
      salesforce_excluded_objects = optional(object({
        objects = map(object({
          object_name = optional(string)
          fields      = optional(list(object({ name = optional(string) })))
        }))
      }))
    }))
    backfill_none = optional(bool)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, s in var.streams : can(regex("^[a-z][-a-z0-9]{0,62}[a-z0-9]$", s.stream_id))])
    error_message = "stream_id must be 2-63 characters, start with a lowercase letter, end with a lowercase letter or digit, and contain only hyphens, lowercase letters and digits."
  }

  validation {
    condition     = alltrue([for k, s in var.streams : s.desired_state == null || contains(["NOT_STARTED", "RUNNING", "PAUSED"], s.desired_state)])
    error_message = "desired_state must be one of NOT_STARTED, RUNNING or PAUSED (case-sensitive; defaults to NOT_STARTED)."
  }

  validation {
    condition     = alltrue([for k, s in var.streams : s.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], s.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive; defaults to DELETE)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      sum([for f in [
        s.source_config.mysql_source_config != null,
        s.source_config.postgresql_source_config != null,
        s.source_config.oracle_source_config != null,
        s.source_config.sql_server_source_config != null,
        s.source_config.salesforce_source_config != null,
      ] : f ? 1 : 0]) == 1
    ])
    error_message = "each stream requires exactly one source config block: mysql_source_config, postgresql_source_config, oracle_source_config, sql_server_source_config or salesforce_source_config (spanner_source_config and mongodb_source_config are deferred; see README)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      sum([for f in [
        s.destination_config.gcs_destination_config != null,
        s.destination_config.bigquery_destination_config != null,
      ] : f ? 1 : 0]) == 1
    ])
    error_message = "each stream requires exactly one destination config block: gcs_destination_config or bigquery_destination_config."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      sum([for f in [s.backfill_all != null, s.backfill_none == true] : f ? 1 : 0]) == 1
    ])
    error_message = "each stream requires exactly one of backfill_all or backfill_none = true."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      sum([for f in [s.source_config.source_connection_profile_key != null, s.source_config.source_connection_profile != null] : f ? 1 : 0]) == 1
    ])
    error_message = "source_config requires exactly one of source_connection_profile_key (a key into var.connection_profiles) or source_connection_profile (a full resource ID)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.source_connection_profile_key == null ||
      contains(keys(var.connection_profiles), s.source_config.source_connection_profile_key)
    ])
    error_message = "source_config.source_connection_profile_key must be a key of var.connection_profiles."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      sum([for f in [s.destination_config.destination_connection_profile_key != null, s.destination_config.destination_connection_profile != null] : f ? 1 : 0]) == 1
    ])
    error_message = "destination_config requires exactly one of destination_connection_profile_key (a key into var.connection_profiles) or destination_connection_profile (a full resource ID)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.destination_connection_profile_key == null ||
      contains(keys(var.connection_profiles), s.destination_config.destination_connection_profile_key)
    ])
    error_message = "destination_config.destination_connection_profile_key must be a key of var.connection_profiles."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.mysql_source_config == null ||
      sum([for f in [s.source_config.mysql_source_config.binary_log_position == true, s.source_config.mysql_source_config.gtid == true] : f ? 1 : 0]) <= 1
    ])
    error_message = "mysql_source_config accepts at most one of binary_log_position = true or gtid = true (CDC reader method)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.oracle_source_config == null ||
      sum([for f in [s.source_config.oracle_source_config.drop_large_objects == true, s.source_config.oracle_source_config.stream_large_objects == true] : f ? 1 : 0]) <= 1
    ])
    error_message = "oracle_source_config accepts at most one of drop_large_objects = true or stream_large_objects = true."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.sql_server_source_config == null ||
      sum([for f in [s.source_config.sql_server_source_config.transaction_logs == true, s.source_config.sql_server_source_config.change_tables == true] : f ? 1 : 0]) <= 1
    ])
    error_message = "sql_server_source_config accepts at most one of transaction_logs = true or change_tables = true (CDC reader method)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.salesforce_source_config == null || (can(regex("^[0-9]+s$", s.source_config.salesforce_source_config.polling_interval)) &&
        tonumber(trimsuffix(s.source_config.salesforce_source_config.polling_interval, "s")) >= 300 &&
      tonumber(trimsuffix(s.source_config.salesforce_source_config.polling_interval, "s")) <= 86400)
    ])
    error_message = "salesforce_source_config.polling_interval must be a whole-second duration string in seconds (e.g. \"600s\") between 300s (5 minutes) and 86400s (24 hours); fractional seconds are deliberately not accepted."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.salesforce_source_config == null ||
      (s.source_config.salesforce_source_config.include_objects == null || length(s.source_config.salesforce_source_config.include_objects.objects) > 0) &&
      (s.source_config.salesforce_source_config.exclude_objects == null || length(s.source_config.salesforce_source_config.exclude_objects.objects) > 0)
    ])
    error_message = "salesforce_source_config include_objects.objects and exclude_objects.objects must be non-empty when the block is present (the provider requires at least one objects entry)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.mysql_source_config == null ||
      (s.source_config.mysql_source_config.include_objects == null || length(s.source_config.mysql_source_config.include_objects.mysql_databases) > 0) &&
      (s.source_config.mysql_source_config.exclude_objects == null || length(s.source_config.mysql_source_config.exclude_objects.mysql_databases) > 0)
    ])
    error_message = "mysql_source_config include_objects.mysql_databases and exclude_objects.mysql_databases must be non-empty when the block is present (the provider requires at least one databases entry; an empty include_objects cannot be expressed)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.postgresql_source_config == null ||
      (s.source_config.postgresql_source_config.include_objects == null || length(s.source_config.postgresql_source_config.include_objects.postgresql_schemas) > 0) &&
      (s.source_config.postgresql_source_config.exclude_objects == null || length(s.source_config.postgresql_source_config.exclude_objects.postgresql_schemas) > 0)
    ])
    error_message = "postgresql_source_config include_objects.postgresql_schemas and exclude_objects.postgresql_schemas must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.oracle_source_config == null ||
      (s.source_config.oracle_source_config.include_objects == null || length(s.source_config.oracle_source_config.include_objects.oracle_schemas) > 0) &&
      (s.source_config.oracle_source_config.exclude_objects == null || length(s.source_config.oracle_source_config.exclude_objects.oracle_schemas) > 0)
    ])
    error_message = "oracle_source_config include_objects.oracle_schemas and exclude_objects.oracle_schemas must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.source_config.sql_server_source_config == null ||
      (s.source_config.sql_server_source_config.include_objects == null || length(s.source_config.sql_server_source_config.include_objects.schemas) > 0) &&
      (s.source_config.sql_server_source_config.exclude_objects == null || length(s.source_config.sql_server_source_config.exclude_objects.schemas) > 0)
    ])
    error_message = "sql_server_source_config include_objects.schemas and exclude_objects.schemas must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.backfill_all == null || s.backfill_all.mysql_excluded_objects == null || length(s.backfill_all.mysql_excluded_objects.mysql_databases) > 0
    ])
    error_message = "backfill_all.mysql_excluded_objects.mysql_databases must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.backfill_all == null || s.backfill_all.postgresql_excluded_objects == null || length(s.backfill_all.postgresql_excluded_objects.postgresql_schemas) > 0
    ])
    error_message = "backfill_all.postgresql_excluded_objects.postgresql_schemas must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.backfill_all == null || s.backfill_all.oracle_excluded_objects == null || length(s.backfill_all.oracle_excluded_objects.oracle_schemas) > 0
    ])
    error_message = "backfill_all.oracle_excluded_objects.oracle_schemas must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.backfill_all == null || s.backfill_all.sql_server_excluded_objects == null || length(s.backfill_all.sql_server_excluded_objects.schemas) > 0
    ])
    error_message = "backfill_all.sql_server_excluded_objects.schemas must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.backfill_all == null || s.backfill_all.salesforce_excluded_objects == null || length(s.backfill_all.salesforce_excluded_objects.objects) > 0
    ])
    error_message = "backfill_all.salesforce_excluded_objects.objects must be non-empty when the block is present."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.gcs_destination_config == null ||
      sum([for f in [s.destination_config.gcs_destination_config.avro_file_format == true, s.destination_config.gcs_destination_config.json_file_format != null] : f ? 1 : 0]) <= 1
    ])
    error_message = "gcs_destination_config accepts at most one of avro_file_format = true or json_file_format (file format)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.gcs_destination_config == null || s.destination_config.gcs_destination_config.file_rotation_interval == null ||
      (can(regex("^[0-9]+s$", s.destination_config.gcs_destination_config.file_rotation_interval)) &&
        tonumber(trimsuffix(s.destination_config.gcs_destination_config.file_rotation_interval, "s")) >= 15 &&
      tonumber(trimsuffix(s.destination_config.gcs_destination_config.file_rotation_interval, "s")) <= 60)
    ])
    error_message = "gcs_destination_config.file_rotation_interval must be a whole-second duration string in seconds (e.g. \"60s\") between 15s and 60s; fractional seconds are deliberately not accepted."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.gcs_destination_config == null || s.destination_config.gcs_destination_config.json_file_format == null ||
      (s.destination_config.gcs_destination_config.json_file_format.schema_file_format == null ||
      contains(["NO_SCHEMA_FILE", "AVRO_SCHEMA_FILE"], s.destination_config.gcs_destination_config.json_file_format.schema_file_format))
    ])
    error_message = "gcs_destination_config.json_file_format.schema_file_format must be NO_SCHEMA_FILE or AVRO_SCHEMA_FILE (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.gcs_destination_config == null || s.destination_config.gcs_destination_config.json_file_format == null ||
      (s.destination_config.gcs_destination_config.json_file_format.compression == null ||
      contains(["NO_COMPRESSION", "GZIP"], s.destination_config.gcs_destination_config.json_file_format.compression))
    ])
    error_message = "gcs_destination_config.json_file_format.compression must be NO_COMPRESSION or GZIP (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.bigquery_destination_config == null ||
      sum([for f in [
        s.destination_config.bigquery_destination_config.single_target_dataset != null,
        s.destination_config.bigquery_destination_config.source_hierarchy_datasets != null,
      ] : f ? 1 : 0]) == 1
    ])
    error_message = "bigquery_destination_config requires exactly one of single_target_dataset or source_hierarchy_datasets; blmt_config is an independent optional block that may accompany either."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.bigquery_destination_config == null ||
      sum([for f in [s.destination_config.bigquery_destination_config.merge == true, s.destination_config.bigquery_destination_config.append_only == true] : f ? 1 : 0]) <= 1
    ])
    error_message = "bigquery_destination_config accepts at most one of merge = true or append_only = true (write mode; defaults to merge server-side)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.bigquery_destination_config == null || s.destination_config.bigquery_destination_config.blmt_config == null ||
      (contains(["PARQUET"], s.destination_config.bigquery_destination_config.blmt_config.file_format) &&
      contains(["ICEBERG"], s.destination_config.bigquery_destination_config.blmt_config.table_format))
    ])
    error_message = "bigquery_destination_config.blmt_config.file_format must be PARQUET and table_format must be ICEBERG (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for k, s in var.streams :
      s.destination_config.bigquery_destination_config == null || s.destination_config.bigquery_destination_config.data_freshness == null ||
      can(regex("^[0-9]+s$", s.destination_config.bigquery_destination_config.data_freshness))
    ])
    error_message = "bigquery_destination_config.data_freshness must be a whole-second duration string in seconds (e.g. \"900s\"); defaults to 900s and only affects tables created after the change."
  }
}
