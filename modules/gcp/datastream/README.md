# gcp/datastream

Map-keyed module for Google Cloud Datastream: private connections (VPC
peering or PSC interfaces), connection profiles (Oracle, MySQL, PostgreSQL,
SQL Server, MongoDB, Cloud Storage, BigQuery), and CDC streams to BigQuery
or Cloud Storage.

**Salesforce and Spanner connection profiles are not modeled** —
`salesforce_profile` and `spanner_profile` are beta-only in the provider
(examples use `provider = google-beta`) and this module keeps everything GA.
A Salesforce *stream* is still possible via the GA
`salesforce_source_config`, but it requires a consumer-managed
`google-beta` connection profile (reference it by full resource ID).
`spanner_source_config` and `mongodb_source_config` on streams, and
`rule_sets` (BigQuery partitioning/clustering customization), are GA but
deferred to a follow-up release.

## Stream lifecycle (read before using)

- Streams are created with `desired_state = NOT_STARTED` by default — a
  stream created by this module does not start until explicitly set to
  `RUNNING`. `PAUSED` is only valid coming from `RUNNING`.
- Updating `source_config`/`destination_config` on a `RUNNING` stream can
  fail server-side; the safe sequence is `desired_state = PAUSED` → apply
  the config change → back to `RUNNING`.
- `state` is computed: a stream stopped/started outside Terraform shows
  drift on `desired_state`.
- `stream_id`, `location`, the profile/connection ids and locations, and a
  stream's `customer_managed_encryption_key` are immutable — changing them
  recreates the resource. A stream's source/destination connection profile
  references are immutable too (changing one recreates the stream), as are
  the credential fields of a profile (SSL certs, SSH password/private key).
- Engine profile blocks otherwise update in place — but changing the
  engine type of a profile that a stream references breaks that stream
  server-side (the stream keeps referencing the same profile id, now with
  a different engine). Prefer a new profile id and recreate the stream.
- Changing the backfill strategy on an existing stream triggers re-backfill
  behavior server-side.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `private_connections` | `map(object)` | `{}` | Private connections keyed by an arbitrary unique ID; see `private_connections` object table. |
| `connection_profiles` | `map(object)` | `{}` | Connection profiles keyed by an arbitrary unique ID; see `connection_profiles` object table. |
| `streams` | `map(object)` | `{}` | Streams keyed by an arbitrary unique ID; see `streams` object table. |

### `private_connections` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `private_connection_id` | `string` | — | Private connection id; lowercase letters/digits/hyphens (validated). Immutable. |
| `display_name` | `string` | — | Descriptive name shown in UIs. |
| `location` | `string` | — | Location of the private connection. Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `labels` | `map(string)` | `{}` | User labels; non-authoritative (see `effective_labels` on the resource). |
| `deletion_policy` | `string` | — | One of `DEFAULT`, `FORCE`, `PREVENT`, `ABANDON` (case-sensitive, validated). Defaults to `FORCE` server-side — `FORCE` also deletes child routes. |
| `create_without_validation` | `bool` | — | Skip connectivity validation on create. |
| `vpc_peering_config` | `object` | — | `{vpc, subnet}` — VPC peering to the consumer VPC. Exactly one of `vpc_peering_config` / `psc_interface_config` (validated). |
| `psc_interface_config` | `object` | — | `{network_attachment}` — PSC interface via a network attachment (`projects/{project}/regions/{region}/networkAttachments/{name}`); requires a recent `hashicorp/google` provider. Exactly one of the two (validated). |

### `connection_profiles` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `connection_profile_id` | `string` | — | Connection profile id; lowercase letters/digits/hyphens (validated). Immutable. |
| `display_name` | `string` | — | Descriptive name shown in UIs. |
| `location` | `string` | — | Location of the connection profile. Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `labels` | `map(string)` | `{}` | User labels; non-authoritative (see `effective_labels` on the resource). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated); defaults to `DELETE`. |
| `create_without_validation` | `bool` | — | Create without validating connectivity/credentials. |
| `oracle_profile` | `object` | — | `{hostname, username, database_service, port, password, secret_manager_stored_password, connection_attributes}`. Exactly one engine profile per entry (validated). |
| `mysql_profile` | `object` | — | `{hostname, username, port, password, secret_manager_stored_password, ssl_config}`; see `mysql_profile.ssl_config` table. |
| `postgresql_profile` | `object` | — | `{hostname, username, database, port, password, secret_manager_stored_password, ssl_config}`; see `postgresql_profile.ssl_config` table. |
| `sql_server_profile` | `object` | — | `{hostname, username, database, port, password, secret_manager_stored_password}`. |
| `mongodb_profile` | `object` | — | `{host_addresses, username, password, secret_manager_stored_password, replica_set, additional_options, ssl_config, srv_connection_format, standard_connection_format}`; see `mongodb_profile` notes below. |
| `gcs_profile` | `object` | — | `{bucket, root_path}` — Cloud Storage destination profile. |
| `bigquery_profile` | `bool` | — | Set `true` to emit an empty `bigquery_profile {}` block (BigQuery destination). |
| `forward_ssh_connectivity` | `object` | — | `{hostname, username, port, password, private_key}` — forward SSH tunnel. At most one of `forward_ssh_connectivity` / `private_connectivity` (validated). |
| `private_connectivity` | `object` | — | `{private_connection_key, private_connection}` — reference a private connection by key into `var.private_connections` or by full resource ID; exactly one (validated, key must exist). |

Each engine profile requires exactly one of `password` or
`secret_manager_stored_password` (validated) — prefer the Secret Manager
variant to keep secrets out of state.

### `streams` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `stream_id` | `string` | — | Stream id; lowercase letters/digits/hyphens (validated). Immutable. |
| `location` | `string` | — | Location of the stream. Immutable. |
| `display_name` | `string` | — | Descriptive name shown in UIs. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. |
| `labels` | `map(string)` | `{}` | User labels; non-authoritative (see `effective_labels` on the resource). |
| `desired_state` | `string` | — | `NOT_STARTED`, `RUNNING` or `PAUSED` (case-sensitive, validated); defaults to `NOT_STARTED`. See lifecycle note. |
| `customer_managed_encryption_key` | `string` | — | KMS key for stream data encryption. Immutable; changing it recreates the stream. |
| `create_without_validation` | `bool` | — | Create the stream without validating it. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive, validated); defaults to `DELETE`. |
| `source_config` | `object` | — | Required; see `source_config` object table. The profile reference is immutable (changing it recreates the stream); the engine block updates in place (see lifecycle). |
| `destination_config` | `object` | — | Required; see `destination_config` object table. The profile reference is immutable (changing it recreates the stream); the engine block updates in place (see lifecycle). |
| `backfill_all` | `object` | — | Backfill all objects, with optional per-engine exclusions (`mysql_excluded_objects`, `postgresql_excluded_objects`, `oracle_excluded_objects`, `sql_server_excluded_objects`, `salesforce_excluded_objects` — same nested shapes as the matching source configs). Exactly one of `backfill_all` / `backfill_none` (validated). |
| `backfill_none` | `bool` | — | Set `true` to emit an empty `backfill_none {}` block (no automatic backfill). |

### `source_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `source_connection_profile_key` | `string` | — | Key into `var.connection_profiles`. Exactly one of key / full resource ID (validated; key must exist). |
| `source_connection_profile` | `string` | — | Full resource ID (`projects/{project}/locations/{location}/connectionProfiles/{name}`), for externally-managed profiles. |
| `mysql_source_config` | `object` | — | `{include_objects, exclude_objects, max_concurrent_cdc_tasks, max_concurrent_backfill_tasks, binary_log_position, gtid}`. Exactly one source config block (validated). At most one of `binary_log_position` / `gtid` (validated). |
| `postgresql_source_config` | `object` | — | `{replication_slot, publication, max_concurrent_backfill_tasks, include_objects, exclude_objects}`. The replication slot and publication must pre-exist on the source; this module cannot create them. |
| `oracle_source_config` | `object` | — | `{include_objects, exclude_objects, max_concurrent_cdc_tasks, max_concurrent_backfill_tasks, drop_large_objects, stream_large_objects}`. At most one of `drop_large_objects` / `stream_large_objects` (validated). |
| `sql_server_source_config` | `object` | — | `{include_objects, exclude_objects, max_concurrent_cdc_tasks, max_concurrent_backfill_tasks, transaction_logs, change_tables}`. At most one of `transaction_logs` / `change_tables` (validated). |
| `salesforce_source_config` | `object` | — | `{polling_interval, include_objects, exclude_objects}`; `polling_interval` is a whole-second string between `300s` and `86400s` (validated — stricter than the API, which allows fractional seconds). Requires a consumer-managed `google-beta` connection profile; see the beta note above. |

The `include_objects`/`exclude_objects` blocks carry one required nested
collection per engine (`mysql_databases`, `postgresql_schemas`,
`oracle_schemas`, `schemas`, `objects`) — modeled as maps keyed by an
arbitrary unique ID. When the block is present the collection must be
non-empty (validated): an empty `include_objects` cannot be expressed
(the provider requires the child block), even though the API reads it as
"include everything". Tables are nested maps (`mysql_tables`,
`postgresql_tables`, `oracle_tables`, `tables`) with an optional `table`
name; columns/fields are lists — columns are positional via
`ordinal_position`, salesforce `fields` and mongodb `host_addresses` are
anonymous.

### `destination_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `destination_connection_profile_key` | `string` | — | Key into `var.connection_profiles`. Exactly one of key / full resource ID (validated; key must exist). |
| `destination_connection_profile` | `string` | — | Full resource ID, for externally-managed profiles. |
| `gcs_destination_config` | `object` | — | `{path, file_rotation_mb, file_rotation_interval, avro_file_format, json_file_format}`. Exactly one destination config block (validated). At most one of `avro_file_format` / `json_file_format` (validated). |
| `bigquery_destination_config` | `object` | — | See `bigquery_destination_config` object table. Exactly one destination config block (validated). |

`file_rotation_interval` is a whole-second string between `15s` and `60s`
(validated — stricter than the API, which allows fractional seconds).

### `bigquery_destination_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `data_freshness` | `string` | — | Guaranteed data freshness, e.g. `900s` (default); only affects tables created after the change. |
| `single_target_dataset` | `object` | — | `{dataset_id}` — one dataset for everything (`projects/{project}/datasets/{id}` or `{project}:{id}`). Exactly one of `single_target_dataset` / `source_hierarchy_datasets` (validated). |
| `source_hierarchy_datasets` | `object` | — | `{project_id, dataset_template}` with `dataset_template = {location, dataset_id_prefix, kms_key_name}` — datasets mirror the source hierarchy. |
| `blmt_config` | `object` | — | `{bucket, connection_name, file_format, table_format, root_path}` — BigLake managed tables; independent optional block, may accompany either dataset config. `file_format` must be `PARQUET` and `table_format` `ICEBERG` (validated). Requires a recent `hashicorp/google` provider. |
| `merge` | `bool` | — | Set `true` for merge write mode (default server-side). At most one of `merge` / `append_only` (validated). |
| `append_only` | `bool` | — | Set `true` to retain the historical state of the data. |

## Outputs

`private_connection_ids` — map of private connection key => resource id.
`private_connection_states` — map of private connection key => state.
`connection_profile_ids` — map of connection profile key => resource id
(`projects/{project}/locations/{location}/connectionProfiles/{id}`).
`stream_ids` — map of stream key => resource id.
`stream_states` — map of stream key => current stream state.

## Example

```hcl
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
    destination_config = {
      destination_connection_profile_key = "bq-dest"
      bigquery_destination_config = {
        source_hierarchy_datasets = {
          dataset_template = { location = "europe-west1", dataset_id_prefix = "ds" }
        }
        append_only = true
      }
    }
    backfill_all = {
      postgresql_excluded_objects = {
        "staging" = { schema = "staging" }
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
        gtid = true
        include_objects = {
          "app" = {
            database = "appdb"
            mysql_tables = {
              "orders" = { table = "orders" }
            }
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
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names — multiple
  streams can share a `stream_id` across locations, and nested
  database/schema/table maps can repeat names. Nested collection keys
  never appear in outputs (no composite keys needed; the three collections
  are independent maps).
- Cross-references are by key (`*_key` into the relevant map) or by full
  resource ID for externally-managed profiles/connections — exactly one,
  validated, and the key must exist.
- Secrets (`password`, SSL keys, SSH keys) are stored plain-text in state;
  prefer the `secret_manager_stored_password` variants.
- The Datastream service account
  (`service-<project-number>@gcp-sa-datastream.iam.gserviceaccount.com`)
  needs read access on sources and write access on destination
  buckets/datasets, plus `cloudkms.cryptoKeyEncrypterDecrypter` on any CMEK
  keys (streams and `dataset_template.kms_key_name`).
- Pair with `gcp/project-services` (`datastream.googleapis.com`).
- `deletion_policy` defaults differ per resource: private connections
  default to `FORCE` (which also deletes child routes); profiles and
  streams default to `DELETE` and accept only `DELETE`/`PREVENT`/`ABANDON`
  — `FORCE` exists only on private connections.
- PostgreSQL sources require a pre-existing logical replication slot and
  publication; Oracle sources require adequate log retention. Both are
  source-DB prerequisites outside this module.
- `labels` are non-authoritative on all three resources (the provider only
  manages labels present in config; see `effective_labels`).
- BLMT (`blmt_config`) and PSC (`psc_interface_config`) require a
  reasonably recent `hashicorp/google` provider (consumers control
  pinning).
- Duration validations (`file_rotation_interval`, `polling_interval`,
  `data_freshness`) accept only whole-second `"<n>s"` strings — stricter
  than the API, which allows fractional seconds (deliberate).

## Import

`google_datastream_private_connection` ←
`projects/{project}/locations/{location}/privateConnections/{id}`.
`google_datastream_connection_profile` ←
`projects/{project}/locations/{location}/connectionProfiles/{id}`.
`google_datastream_stream` ←
`projects/{project}/locations/{location}/streams/{id}`.
