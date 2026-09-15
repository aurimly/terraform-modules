# gcp/bigtable

Map-keyed module for Google Cloud Bigtable: instances with nested clusters,
tables (column families, split keys, change streams, automated backups), app
profiles, garbage-collection policies, and IAM bindings.

**`google_bigtable_gc_policy` does not support import — manage GC policies
from day one in Terraform.**

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance id; 6–33 chars, hyphens/lowercase letters/digits (validated). Immutable; changing forces replacement. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `display_name` | `string` | — | Defaults to the instance name server-side. |
| `labels` | `map(string)` | `{}` | User labels. |
| `edition` | `string` | — | One of `ENTERPRISE`, `ENTERPRISE_PLUS` (case-sensitive); defaults to `ENTERPRISE` server-side. |
| `deletion_protection` | `bool` | `true` | Terraform-level protection flag — set to `false` and apply before destroy. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). |
| `force_destroy` | `bool` | — | Delete instance backups (if any) before the instance. |
| `clusters` | `map(object)` | — | Clusters keyed by cluster_id; see `clusters` object table. The deprecated `instance_type` (DEVELOPMENT/PRODUCTION) is deliberately not exposed. |
| `role_bindings` | `map(object)` | `{}` | Instance-level IAM bindings; see `role_bindings` object table — one resource per (instance, role). |
| `tables` | `map(object)` | `{}` | Tables keyed by an arbitrary unique ID; see `tables` object table. |
| `app_profiles` | `map(object)` | `{}` | App profiles keyed by an arbitrary unique ID; see `app_profiles` object table. |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_id` | `string` | — | 6–30 chars, hyphens/lowercase letters/digits (validated). Immutable. |
| `zone` | `string` | — | GCP zone; falls back to the provider zone when unset. Explicit zones must be distinct within the instance (validated; unset zones are exempt — set zone explicitly on multi-cluster instances). |
| `num_nodes` | `number` | — | Fixed node count. Exactly one of `num_nodes` / `autoscaling_config` per cluster (validated, deliberately stricter than the API which would ignore `num_nodes` if both were set). |
| `autoscaling_config` | `object` | — | `{min_nodes, max_nodes, cpu_target, storage_target}`; `cpu_target` 10–80, `min_nodes <= max_nodes` (validated). |
| `storage_type` | `string` | — | One of `SSD`, `HDD` (case-sensitive); defaults to `SSD` server-side. Changing forces the whole instance to be recreated. |
| `kms_key_name` | `string` | — | CMEK key (regional, must match the cluster region); changing forces the whole instance to be recreated. |
| `node_scaling_factor` | `string` | — | `NodeScalingFactor1X` or `NodeScalingFactor2X` (API casing); node counts must then be even. Immutable after creation. |

### `tables` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | 1–50 chars, hyphens/underscores/periods/letters/digits (validated). Immutable. |
| `split_keys` | `list(string)` | — | Predefined split keys. Changing it recreates the table (and is not readable back on import). |
| `column_families` | `map(object)` | `{}` | Keyed by family name; value `{type}` where `type` is a family type string. |
| `gc_policies` | `map(object)` | `{}` | GC policies keyed by column family name; see `gc_policies` object table. Only one policy per family is supported here. |
| `deletion_protection` | `string` | — | One of `UNPROTECTED`, `PROTECTED` (case-sensitive). |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). |
| `change_stream_retention` | `string` | — | Duration (e.g. `24h0m0s`), between `1h` and `167h59m59s`, or `0s` to disable. |
| `automated_backup_policy` | `object` | — | `{retention_period, frequency, locations}` durations (e.g. `72h0m0s`); `locations` is optional. |
| `role_bindings` | `map(object)` | `{}` | Table-level IAM bindings; same shape as instance `role_bindings`. |

### `gc_policies` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `max_age` | `object` | — | `{duration}` (e.g. `168h`); exactly one of `max_age`, `max_version`, `gc_rules` (validated). |
| `max_version` | `object` | — | `{number}`; exactly one of the three (validated). |
| `gc_rules` | `string` | — | Serialized JSON (see provider docs examples); conflicts with `max_age`/`max_version` (validated). |
| `mode` | `string` | — | `UNION` or `INTERSECTION` (case-sensitive); only needed when multiple policies share a family — not supported on the same family by this module. |
| `ignore_warnings` | `bool` | — | Allow relaxing the GC policy on replicated clusters by up to 90 days. |
| `deletion_policy` | `string` | — | One of `PREVENT`, `ABANDON`, `DELETE` (case-sensitive). `ABANDON` is common — policies cannot be deleted while the table is replicated. |

### `app_profiles` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `app_profile_id` | `string` | — | `[_a-zA-Z0-9][-_.a-zA-Z0-9]*`. Immutable. |
| `description` | `string` | — | Long-form description. |
| `ignore_warnings` | `bool` | — | Ignore safety checks when deleting/updating. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). |
| `multi_cluster_routing_use_any` | `bool` | — | Nearest-cluster routing. Exactly one of this or `single_cluster_routing` (validated). |
| `multi_cluster_routing_cluster_ids` | `list(string)` | — | Restrict multi-cluster routing to these clusters; may be set alongside `multi_cluster_routing_use_any`. |
| `single_cluster_routing` | `object` | — | `{cluster_id, allow_transactional_writes}`. |
| `standard_isolation` | `object` | — | `{priority}` one of `PRIORITY_LOW`, `PRIORITY_MEDIUM`, `PRIORITY_HIGH` (case-sensitive). |
| `data_boost_isolation_read_only` | `object` | — | `{compute_billing_owner}`; currently only `HOST_PAYS`. |

### `role_bindings` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | — | IAM role, e.g. `roles/bigtable.user`. Must be unique within the instance/table (validated — one binding resource exists per role). |
| `members` | `list(string)` | — | At least one member (validated); authoritative for the role. |
| `condition` | `object` | — | Optional IAM condition `{title, expression, description}`. |

## Outputs

`instance_names` — map of instance key => instance name.
`instance_ids` — map of instance key =>
`projects/<project>/instances/<name>`.
`table_ids` — map of `"<instance key>/<table key>"` => full table id.
`app_profile_ids` — map of `"<instance key>/<profile key>"` => full app
profile id.
`gc_policy_keys` — map of
`"<instance key>/<table key>/<column family>"` => the same key; the GC
policy resource has no exported id and no import, the composite key is the
identifier.
`instance_iam_binding_roles` — map of `"<instance key>/<binding key>"` =>
role.
`table_iam_binding_roles` — map of
`"<instance key>/<table key>/<binding key>"` => role.

## Example

```hcl
instances = {
  "main" = {
    name      = "example-bt-main"
    edition   = "ENTERPRISE_PLUS"
    clusters = {
      "eu" = {
        cluster_id = "example-bt-eu"
        zone       = "europe-west4-a"
        num_nodes  = 3
      }
      "eu2" = {
        cluster_id = "example-bt-eu2"
        zone       = "europe-west4-b"
        autoscaling_config = {
          min_nodes  = 1
          max_nodes  = 3
          cpu_target = 50
        }
      }
    }
    tables = {
      "events" = {
        name                = "event-stream"
        split_keys          = ["a", "b"]
        deletion_protection = "PROTECTED"
        column_families = {
          "raw"  = {}
          "agg"  = { type = "intsum" }
        }
        gc_policies = {
          "raw" = {
            max_age = { duration = "168h" }
          }
        }
        role_bindings = {
          "readers" = {
            role    = "roles/bigtable.reader"
            members = ["serviceAccount:etl@example-prj.iam.gserviceaccount.com"]
          }
        }
      }
    }
    app_profiles = {
      "hot-throughput" = {
        app_profile_id            = "hot-throughput"
        multi_cluster_routing_use_any = true
        multi_cluster_routing_cluster_ids = ["eu"]
        standard_isolation = { priority = "PRIORITY_MEDIUM" }
      }
      "single-writer" = {
        app_profile_id = "single-writer"
        single_cluster_routing = {
          cluster_id                 = "eu"
          allow_transactional_writes = true
        }
      }
    }
    role_bindings = {
      "users" = {
        role    = "roles/bigtable.user"
        members = ["group:example-data@example.com"]
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names. Tables,
  app profiles, GC policies and table IAM bindings use composite keys
  (`<instance key>/<...>`) in the outputs.
- Set `deletion_protection = false` and apply it to state before a destroy
  will go through; the provider docs additionally recommend
  consumer-side `lifecycle { prevent_destroy = true }` on instances and
  tables.
- Changing a cluster's `storage_type`, `zone` or `kms_key_name` deletes and
  recreates the entire instance — use a new `cluster_id` instead.
- Changing `split_keys` recreates the table.
- CMEK requires the Bigtable service account to hold
  `cloudkms.cryptoKeyEncrypterDecrypter` on the key.
- GC policies: multiple policies on one column family are not recommended
  (provider docs warning) and are not supported here; a GC policy on a
  replicated table cannot be destroyed — unreplicate first or use
  `deletion_policy = "ABANDON"` / `ignore_warnings` for the up-to-90-day
  relaxation.
- Pair with `gcp/project-services` (`bigtable.googleapis.com`); IAM
  bindings on instances/tables are authoritative per role.
- Keys in `clusters`, `tables`, `column_families`, `gc_policies` and IAM
  binding maps must not contain `/` (used as composite-key separator,
  validated).

## Import

`google_bigtable_instance` ←
`projects/{project}/instances/{name}`.
`google_bigtable_table` ←
`projects/{project}/instances/{instance}/tables/{name}` (`split_keys` is
not readable back from the API and will show a diff after import).
`google_bigtable_app_profile` ←
`projects/{project}/instances/{instance}/appProfiles/{app_profile_id}`.
`google_bigtable_instance_iam_binding` ←
`projects/{project}/instances/{instance} roles/{role}`.
`google_bigtable_table_iam_binding` ←
`projects/{project}/instances/{instance}/tables/{table} roles/{role}`.
`google_bigtable_gc_policy` — **no import support**; manage from day one.
