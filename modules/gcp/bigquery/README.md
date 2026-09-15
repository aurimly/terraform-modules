# gcp/bigquery

Map-keyed module for BigQuery datasets with nested tables and dataset
access control (native access grants or IAM bindings, per dataset).

Routines, standalone `google_bigquery_dataset_access`, table IAM, external
(AWS Glue) dataset references, BigLake and table constraints are out of
scope.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `datasets` | `map(object)` | — | Map of datasets keyed by an arbitrary unique ID; tables and access grants nest under each dataset and flatten to composite keys (`dataset key/table key`, `dataset key/binding key`). |

### `datasets` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `dataset_id` | `string` | — | Letters, digits and underscores, up to 1024 chars (validated). Immutable; changing it replaces the dataset (data loss — export first). |
| `location` | `string` | — | Region (`us-central1`), multi-region (`US`, `EU`), or cross-cloud (`aws-us-east-1`). Shape-validated, not a location list. Immutable; changing it replaces the dataset. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `friendly_name` | `string` | — | Human-readable name. |
| `description` | `string` | — | Free text. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `default_table_expiration_ms` | `number` | — | Expiration applied to new tables, ms; ≥ 3600000 (validated). Existing tables keep their own expiration. |
| `default_partition_expiration_ms` | `number` | — | Expiration applied to new partitions, ms. |
| `max_time_travel_hours` | `number` | — | 48–168 (validated). Lowered windows reduce storage billing for travel-backup bytes. |
| `default_collation` | `string` | — | Default collation for new STRING columns (e.g. `und:ci`). |
| `is_case_insensitive` | `bool` | — | Case-insensitive table names in the dataset. |
| `storage_billing_model` | `string` | — | One of `LOGICAL`, `PHYSICAL` (validated). Changing it re-bills existing data according to the new model from that moment on. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `delete_contents_on_destroy` | `bool` | — | Destroy tables/views in the dataset on destroy. Required for destroy when the dataset contains content — without it, Terraform errors on the non-empty user-managed dataset. |
| `resource_tags` | `map(string)` | — | User-managed resource tags. |
| `default_encryption_configuration` | `object` | — | `{kms_key_name}` CMEK for new tables. See Notes on key access. |
| `access_grants` | `map(object)` | `{}` | Native BigQuery ACL entries rendered as `access` blocks; see the `access_grants` object table. Mutually exclusive with `role_bindings` per dataset (validated). |
| `tables` | `map(object)` | `{}` | Nested tables; see the `tables` object table. |
| `role_bindings` | `map(object)` | `{}` | Dataset IAM bindings; see the `role_bindings` object table. Mutually exclusive with `access_grants` per dataset (validated). |

### `access_grants` object

Keys are arbitrary unique identifiers. Exactly one identity attribute per
grant (validated): `domain`, `group_by_email`, `user_by_email`,
`special_group`, `iam_member`, `view`, `dataset` or `routine`.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | Legacy role (`OWNER`, `WRITER`, `READER`) or a custom role; see Notes — do not put predefined `roles/bigquery.*` here. Optional only for `view` and `routine` grants and authorized datasets with `target_types = ["VIEWS"]` (validated). |
| `domain` | `string` | — | Grants on an entire DNS domain. |
| `group_by_email` | `string` | — | Grants on a Google Group. |
| `user_by_email` | `string` | — | Grants on a single user. |
| `special_group` | `string` | — | One of `projectOwners`, `projectReaders`, `projectWriters`, `allAuthenticatedUsers`. |
| `iam_member` | `string` | — | IAM member (e.g. `serviceAccount:...`) bridging IAM policy to the dataset ACL. |
| `view` | `object` | — | Authorized view `{project_id, dataset_id, table_id}`. |
| `dataset` | `object` | — | Authorized dataset `{target_types, dataset {project_id, dataset_id}}` where the inner object identifies the **target** dataset; `target_types` must be `["VIEWS"]` (validated) and makes `role` optional. |
| `routine` | `object` | — | Authorized routine `{project_id, dataset_id, routine_id}`. |
| `condition` | `object` | — | Optional `{title, description, expression}` (the provider access condition also supports `location`, omitted here). |

### `tables` object

Keys are arbitrary unique identifiers. Exactly one table shape per table:
`view`, `materialized_view`, `external_data_configuration`, or a physical
table with `schema` (validated).

| Attribute | Type | Default | Description |
|---|---|---|---|
| `table_id` | `string` | — | Letters, digits and underscores, up to 1024 chars (validated); views in the same dataset count against this name space and cannot start with a digit or underscore. |
| `project_id` | `string` | — | Override of the parent dataset project; defaults to the parent's `project_id` (which itself defaults to the provider-level project). Format validated. |
| `friendly_name` | `string` | — | Human-readable name. |
| `description` | `string` | — | Free text. |
| `labels` | `map(string)` | `{}` | User labels, passed through unchanged. |
| `expiration_time` | `number` | — | Table expiration, epoch ms (overrides the dataset's `default_table_expiration_ms`). |
| `require_partition_filter` | `bool` | — | Force queries to filter on the partition column. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (validated). |
| `deletion_protection` | `bool` | — | Terraform-side destroy guard — set to `false` explicitly (and apply) before destroy. |
| `schema` | `string` | — | JSON list of field objects (e.g. `[{"name": "id", "type": "STRING"}]`); JSON-validated. Required for physical tables (validated). |
| `ignore_auto_generated_schema` | `bool` | — | Let the API auto-create the schema (e.g. for views) without a plan diff. |
| `clustering` | `list(string)` | — | Up to 4 columns (validated); requires partitioning (validated). |
| `resource_tags` | `map(string)` | — | Resource tags. |
| `time_partitioning` | `object` | — | `{type, field, expiration_ms}`; type one of `DAY`, `HOUR`, `MONTH`, `YEAR` (validated). Exclusive with `range_partitioning` (validated). |
| `range_partitioning` | `object` | — | `{field, range{start, end, interval}}`; requires start < end, interval > 0 and interval ≤ end − start (validated). |
| `view` | `object` | — | `{query, use_legacy_sql}`; conflicts with `schema` (validated). |
| `materialized_view` | `object` | — | `{query, enable_refresh, refresh_interval_ms, allow_non_incremental_definition}`; conflicts with `schema` (validated). |
| `encryption_configuration` | `object` | — | `{kms_key_name}` CMEK for the table. |
| `external_data_configuration` | `object` | — | External table; see the `external_data_configuration` object table. |

### `external_data_configuration` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `autodetect` | `bool` | — | Schema auto-detection (alternative to `schema`, validated). |
| `source_format` | `string` | — | e.g. `CSV`, `NEWLINE_DELIMITED_JSON`, `PARQUET`. |
| `source_uris` | `list(string)` | — | At least one `gs://` URI (validated). |
| `schema` | `string` | — | JSON list of field objects, inside this block — see Notes for where the schema lives per provider docs. |
| `connection_id` | `string` | — | External connection resource; when set, the schema goes in the top-level `schema` field of the table and must not be set here (validated). |
| `ignore_unknown_values` | `bool` | — | Skip extra source columns. |
| `max_bad_records` | `number` | — | Tolerated bad records in a job. |
| `compression` | `string` | — | e.g. `GZIP`. |
| `csv_options` | `object` | — | `{quote, skip_leading_rows, field_delimiter, allow_jagged_rows, allow_quoted_newlines, encoding}`; `quote` is required (provider limitation, validated). |
| `google_sheets_options` | `object` | — | `{skip_leading_rows, range}`; at least one required (validated). |
| `hive_partitioning_options` | `object` | — | `{mode, source_uri_prefix, require_partition_filter}`; mode one of `AUTO`, `STRING`, `CUSTOM` (validated). |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | Predefined (`roles/bigquery.dataViewer`) or fully qualified custom role (`projects/{project}/roles/{id}`); bare legacy roles are rejected (validated — see Notes). Unique within the dataset (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role on the dataset. |
| `condition` | `object` | — | Optional IAM condition; `expression` required, `title`/`description` optional. |

## Outputs

`dataset_ids` — map of dataset key => fully-qualified dataset ID
(`projects/{project}/datasets/{dataset_id}`).
`dataset_self_links` — map of dataset key => dataset self link.
`table_ids` — map of composite table key (`dataset key/table key`) =>
fully-qualified table ID.
`table_self_links` — same composite key => table self link.
`dataset_iam_binding_roles` — map of composite IAM binding key
(`dataset key/binding key`) => role.

## Example

```hcl
datasets = {
  "analytics" = {
    dataset_id                  = "example_analytics"
    location                    = "EU"
    max_time_travel_hours       = 72
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
        table_id              = "example_events"
        expiration_time       = 1798764123000
        require_partition_filter = true
        clustering            = ["event_type"]
        schema                = "[{\"name\": \"event_id\", \"type\": \"STRING\", \"mode\": \"REQUIRED\"}, {\"name\": \"event_at\", \"type\": \"TIMESTAMP\", \"mode\": \"REQUIRED\"}, {\"name\": \"event_type\", \"type\": \"STRING\"}]"
        time_partitioning = {
          type          = "DAY"
          field         = "event_at"
          expiration_ms = 7776000000
        }
      }
      "latest" = {
        table_id = "example_latest_events"
        view = {
          query = "SELECT event_id, event_at, event_type FROM example_analytics.example_events WHERE event_at = (SELECT MAX(event_at) FROM example_analytics.example_events)"
          use_legacy_sql = false
        }
        ignore_auto_generated_schema = true
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
      "ci" = {
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
```

## Notes

- Keys are arbitrary unique identifiers and must not contain `/` (validated) —
  `/` is the composite-key separator: tables flatten to
  `dataset key/table key`, IAM bindings to `dataset key/binding key`.
- `access_grants` and `role_bindings` cannot coexist on one dataset
  (validated). The provider does not error at apply when both are present —
  the IAM binding resources silently overwrite the dataset access policy on
  every apply, dropping access entries and authorized-view grants, which the
  validation rejects as a config that "succeeds" but misbehaves.
- Legacy roles and predefined roles behave differently on the two surfaces.
  In `access_grants` the API normalizes values: bare `OWNER`/`WRITER`/`READER`
  round-trip cleanly, but predefined `roles/bigquery.*` entries come back in
  legacy form, producing a permanent plan diff — prefer legacy or custom
  roles there. IAM bindings (`role_bindings`) are the opposite: the provider
  requires `roles/bigquery.*` (or custom roles) on them, and rejects the bare
  legacy names.
- CMEK (`default_encryption_configuration`, table
  `encryption_configuration`) needs the BigQuery service agent of the
  dataset's project granted on the key — pair with `gcp/kms`.
- Pair with `gcp/project-services` (`bigquery.googleapis.com`); this module
  does not enable APIs itself.
- `location` and `dataset_id` are immutable; changing either replaces the
  dataset and its content. Replication between locations is customer-managed.
- Schema is diff-sensitive on the API side: the provider docs call out that
  reordered schema entries or `STRUCT`/`RECORD` naming differences surface as
  permanent diffs — keep the JSON stable or set
  `ignore_auto_generated_schema = true` where the API owns the schema.
- `deletion_protection` (table) and `deletion_policy` (dataset and table) are
  the two destroy guards; with datasets note `delete_contents_on_destroy` for
  the content side.

## Import

`google_bigquery_dataset` ← `projects/{project}/datasets/{dataset_id}`.
`google_bigquery_table` ← `projects/{project}/datasets/{dataset_id}/tables/{table_id}`.
`google_bigquery_dataset_iam_binding` ← space-delimited
`projects/{project}/datasets/{dataset_id} roles/bigquery.dataViewer`.
