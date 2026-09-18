# gcp/spanner

Map-keyed module for Google Cloud Spanner: instances (fixed nodes,
processing units, or autoscaling incl. asymmetric per-replica options) with
nested databases (CMEK, dialect, drop protection) and instance/database IAM
bindings.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance id; 6–30 chars, starts with a lowercase letter, ends with a lowercase letter or digit, hyphens/lowercase letters/digits (validated). Immutable. |
| `display_name` | `string` | — | Descriptive name shown in UIs; 4–30 chars and unique per project (length validated). |
| `config` | `string` | — | Instance configuration, e.g. `regional-europe-west1` or `nam-eur-asia1`. Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `labels` | `map(string)` | `{}` | User labels; non-authoritative (see `effective_labels` on the resource). |
| `edition` | `string` | — | One of `EDITION_UNSPECIFIED`, `STANDARD`, `ENTERPRISE`, `ENTERPRISE_PLUS` (case-sensitive). Must not be set for `FREE_INSTANCE` (validated). |
| `instance_type` | `string` | — | `PROVISIONED` or `FREE_INSTANCE` (case-sensitive). |
| `num_nodes` | `number` | — | Fixed node count. Exactly one of `num_nodes` / `processing_units` / `autoscaling_config` per instance (validated, unless `FREE_INSTANCE`). |
| `processing_units` | `number` | — | Fixed processing-unit count (100/500, then multiples of 1000). Exactly one of the three (validated). |
| `autoscaling_config` | `object` | — | `{autoscaling_limits, autoscaling_targets, asymmetric_autoscaling_options}`; see `autoscaling_config` object table. Exactly one of the three capacity forms (validated). |
| `default_backup_schedule_type` | `string` | — | `NONE` or `AUTOMATIC` (case-sensitive); `AUTOMATIC` is not permitted for `FREE_INSTANCE` (validated). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). |
| `force_destroy` | `bool` | — | Delete instance backups (if any) before the instance. |
| `role_bindings` | `map(object)` | `{}` | Instance-level IAM bindings; see `role_bindings` object table — one resource per (instance, role). |
| `databases` | `map(object)` | `{}` | Databases keyed by an arbitrary unique ID; see `databases` object table. |

### `autoscaling_config` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `autoscaling_limits` | `object` | — | `{min_nodes, max_nodes}` or `{min_processing_units, max_processing_units}` — exactly one unit pair (validated; min ≤ max, `min_nodes` ≥ 1, processing units multiples of 1000). |
| `autoscaling_targets` | `object` | — | `{high_priority_cpu_utilization_percent, storage_utilization_percent, total_cpu_utilization_percent}`; `total_cpu_utilization_percent` must be 10–90 and higher than the high-priority target when both are set (validated). |
| `asymmetric_autoscaling_options` | `map(object)` | — | Per-replica options keyed by an arbitrary unique ID; `{replica_selection = {location}, overrides = {autoscaling_limits, autoscaling_target_high_priority_cpu_utilization_percent, autoscaling_target_total_cpu_utilization_percent, disable_high_priority_cpu_autoscaling, disable_total_cpu_autoscaling}}`. `overrides.autoscaling_limits` follows the same unit-pair validation as the top-level limits. |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Must match `^[a-z][-_a-z0-9]*[a-z0-9]$` (validated). Immutable. |
| `ddl` | `list(string)` | — | DDL statements run at creation (atomically) and appended on update. Modifying a prior statement forces recreation; Terraform does no drift detection on `ddl`. |
| `version_retention_period` | `string` | — | Between 1h and 7 days (e.g. `3d`). If used, do not add DDL statements to `ddl` that update the database's retention period. |
| `default_time_zone` | `string` | — | tz-database name; defaults to `America/Los_angeles` server-side. |
| `database_dialect` | `string` | — | `GOOGLE_STANDARD_SQL` or `POSTGRESQL` (case-sensitive); defaults to `GOOGLE_STANDARD_SQL`. Immutable. |
| `enable_drop_protection` | `bool` | — | Protects the database from deletion in **all** interfaces (and blocks deletion of the parent instance) — unlike `deletion_protection`, which only gates Terraform. Defaults to false. |
| `deletion_protection` | `bool` | `true` | Terraform-level protection flag — set to `false` and apply before destroy. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). |
| `encryption_config` | `object` | — | Exactly one of `kms_key_name` or `kms_key_names` (list for multi-region; validated, deliberately stricter than the API). Keys must exist in the same location(s) as the database. |
| `role_bindings` | `map(object)` | `{}` | Database-level IAM bindings; same shape as instance `role_bindings`. |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/spanner.databaseReader`. Must be unique within the instance/database (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`instance_names` — map of instance key => instance name.
`instance_ids` — map of instance key => instance id (`<project>/<name>`).
`database_ids` — map of `"<instance key>/<database key>"` => database id
(`<instance>/<name>`).
`instance_iam_binding_roles` — map of `"<instance key>/<binding key>"` =>
role.
`database_iam_binding_roles` — map of
`"<instance key>/<database key>/<binding key>"` => role.

## Example

```hcl
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
            autoscaling_limits = { min_nodes = 1, max_nodes = 2 }
          }
        }
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names. Databases,
  database IAM bindings and IAM binding maps use composite keys
  (`<instance key>/<...>`) in the outputs.
- `deletion_protection` on databases defaults to `true`: set it to `false`
  and apply it to state before a destroy will go through.
  `enable_drop_protection` is the stronger, API-level guard (all interfaces,
  plus blocks deleting the parent instance) — prefer it for production data.
- `ddl` updates are append-only; changing a prior statement marks the
  database for recreation. Terraform does not detect drift in `ddl` applied
  outside Terraform (e.g. migrations run out-of-band).
- `FREE_INSTANCE` cannot set `edition` or `default_backup_schedule_type =
  AUTOMATIC` (backups are not allowed on free instances) — both validated.
- CMEK requires the Spanner service account to hold
  `cloudkms.cryptoKeyEncrypterDecrypter` on the keys.
- Pair with `gcp/project-services` (`spanner.googleapis.com`); IAM bindings
  on instances/databases are authoritative per role.
- Keys in `databases` and IAM binding maps must not contain `/` (used as
  composite-key separator, validated).

## Import

`google_spanner_instance` ←
`projects/{project}/instances/{name}`.
`google_spanner_database` ←
`projects/{project}/instances/{instance}/databases/{name}`.
`google_spanner_instance_iam_binding` ←
`{project}/{instance} roles/{role}`.
`google_spanner_database_iam_binding` ←
`{project}/{instance}/{database} roles/{role}`.
