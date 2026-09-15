# gcp/alloydb

Map-keyed module for Google Cloud AlloyDB: clusters with nested instances
(primary, read pool, secondary) and nested on-demand backups, plus CMEK,
continuous-backup, and automated-backup configuration. Users are out of scope
(no `google_alloydb_user`).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | — | Map of clusters keyed by an arbitrary unique ID. |

### `clusters` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `cluster_id` | `string` | — | Cluster id; up to 63 chars, lowercase letters, digits, hyphens, starts with a letter (validated). Immutable; changing forces replacement. |
| `location` | `string` | — | Region name (e.g. `europe-west4`) (shape validated). Immutable. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. Nested instances and backups inherit it. |
| `cluster_type` | `string` | `PRIMARY` | One of `PRIMARY`, `SECONDARY` (case-sensitive). `SECONDARY` requires `secondary_config` (validated both ways). |
| `database_version` | `string` | — | `POSTGRES_<n>` (e.g. `POSTGRES_15`, validated). Changing to a higher version is an irreversible upgrade. |
| `display_name` | `string` | — | Human-readable display name. |
| `labels` | `map(string)` | `{}` | User labels. |
| `annotations` | `map(string)` | `{}` | Client-tool annotations. |
| `deletion_protection` | `bool` | `true` | Terraform-level protection flag — set to `false` explicitly to allow destroy. |
| `deletion_policy` | `string` | — | One of `DEFAULT`, `FORCE`, `PREVENT`, `ABANDON`, `DELETE` (case-sensitive). A SECONDARY cluster requires `FORCE` to delete (see Notes). |
| `subscription_type` | `string` | — | One of `TRIAL`, `STANDARD` (case-sensitive). |
| `skip_await_major_version_upgrade` | `bool` | — | Skip awaiting on the major version upgrade. |
| `network_config` | `object` | — | `{network, allocated_ip_range}`; `network` is the `projects/<n>/global/networks/<id>` self link. Clusters are private-IP only — see Notes. |
| `encryption_config` | `object` | — | `{kms_key_name}` fully-qualified CMEK key for the cluster. |
| `initial_user` | `object` | — | `{user, password}` created at cluster creation. Password is stored in state in plain text (sensitive in plan output) — see Notes. |
| `continuous_backup_config` | `object` | — | `{enabled, recovery_window_days, encryption_config{kms_key_name}}`; `recovery_window_days` >= 1 (validated), defaults to 14 server-side. |
| `automated_backup_policy` | `object` | — | See `automated_backup_policy` object table. Requires exactly one of `time_based_retention` / `quantity_based_retention` (validated). |
| `secondary_config` | `object` | — | `{primary_cluster_name}` fully-qualified; only for `cluster_type = "SECONDARY"` (validated). |
| `maintenance_update_policy` | `object` | — | `{maintenance_windows: [{day, start_time{hours, minutes, seconds, nanos}}]}`; currently one window server-side. Day MONDAY–SUNDAY, start time is an exact hour (validated). |
| `psc_config` | `object` | — | `{psc_enabled}` for Private Service Connect connectivity. |
| `instances` | `map(object)` | `{}` | Nested instances keyed by an arbitrary unique ID; see `instances` object table. |
| `backups` | `map(object)` | `{}` | Nested on-demand backups keyed by an arbitrary unique ID; see `backups` object table. |

### `automated_backup_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | — | Whether automated backups are enabled. |
| `location` | `string` | — | Backup storage location; currently same-region only. |
| `backup_window` | `string` | — | Duration string in seconds (e.g. `1800s`); must be at least 5 minutes (validated). |
| `labels` | `map(string)` | `{}` | Labels on backups created by the policy. |
| `encryption_config` | `object` | — | `{kms_key_name}` CMEK key for the backups. |
| `weekly_schedule` | `object` | — | `{days_of_week: [MONDAY..SUNDAY], start_times: [{hours, minutes, seconds, nanos}]}`; at least one of each required, start times are exact UTC hours (validated). |
| `time_based_retention` | `object` | — | `{retention_period}` duration string; conflicts with `quantity_based_retention` (validated exactly-one). |
| `quantity_based_retention` | `object` | — | `{count}` number of backups to retain; conflicts with `time_based_retention` (validated exactly-one). |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `instance_id` | `string` | — | Instance id; same shape as `cluster_id` (validated). Immutable. |
| `instance_type` | `string` | — | One of `PRIMARY`, `READ_POOL`, `SECONDARY` (case-sensitive, validated). `READ_POOL` ⇔ `read_pool_config` set (validated both ways). |
| `display_name` | `string` | — | Human-readable display name. |
| `labels` | `map(string)` | `{}` | User labels. |
| `annotations` | `map(string)` | `{}` | Client-tool annotations. |
| `gce_zone` | `string` | — | Zone (e.g. `europe-west4-a`); ZONAL instances only, shape-validated. |
| `database_flags` | `map(string)` | `{}` | Database flags; copied from the primary on read-instance creation. |
| `availability_type` | `string` | — | One of `AVAILABILITY_TYPE_UNSPECIFIED`, `ZONAL`, `REGIONAL` (case-sensitive). Read pools of size 1 can only be zonally available. |
| `activation_policy` | `string` | — | One of `ACTIVATION_POLICY_UNSPECIFIED`, `ALWAYS`, `NEVER` (case-sensitive). |
| `deletion_policy` | `string` | — | One of `DEFAULT`, `FORCE`, `PREVENT`, `ABANDON`, `DELETE` (case-sensitive). Deleting a SECONDARY instance abandons it — see Notes. |
| `machine_config` | `object` | — | `{cpu_count, machine_type}`; `cpu_count` must be >= 2 and match the `machine_type` vCPUs when both are set (validated `>= 2`). |
| `read_pool_config` | `object` | — | `{node_count}`; required for `READ_POOL`, forbidden otherwise (validated). |
| `query_insights_config` | `object` | — | `{query_string_length, record_application_tags, record_client_address, query_plans_per_minute}`. |
| `client_connection_config` | `object` | — | `{require_connectors, ssl_config{ssl_mode}}`; `ssl_mode` one of `ENCRYPTED_ONLY`, `ALLOW_UNENCRYPTED_AND_ENCRYPTED` (case-sensitive, validated). |
| `network_config` | `object` | — | `{enable_public_ip, enable_outbound_public_ip, allocated_ip_range_override, authorized_external_networks: [{cidr_range}]}`. |

### `backups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `backup_id` | `string` | — | Backup id; same shape as `cluster_id` (validated). Immutable. |
| `location` | `string` | — | Backup location (shape-validated). Immutable. |
| `display_name` | `string` | — | Human-readable display name. |
| `labels` | `map(string)` | `{}` | User labels. |
| `description` | `string` | — | User-provided description. |
| `type` | `string` | — | One of `TYPE_UNSPECIFIED`, `ON_DEMAND`, `AUTOMATED`, `CONTINUOUS` (case-sensitive). |
| `deletion_policy` | `string` | — | One of `DEFAULT`, `FORCE`, `PREVENT`, `ABANDON`, `DELETE` (case-sensitive). |
| `encryption_config` | `object` | — | `{kms_key_name}` CMEK key for the backup. |

## Outputs

`cluster_names` — map of cluster key => cluster name (full resource name).
`cluster_ids` — map of cluster key =>
`projects/<project>/locations/<location>/clusters/<cluster_id>`.
`cluster_states` — map of cluster key => serving state.
`instance_names` / `instance_ids` — maps of
`"<cluster key>/<instance key>"` => instance name / id (the latter fully
qualified).
`instance_ip_addresses` — map of `"<cluster key>/<instance key>"` =>
`{ip_address, public_ip_address}`; nulls where not enabled.
`backup_names` / `backup_ids` / `backup_states` — maps of
`"<cluster key>/<backup key>"` => backup name / id / state.

## Example

```hcl
clusters = {
  "app" = {
    cluster_id       = "example-app-cluster"
    location         = "europe-west4"
    database_version = "POSTGRES_15"
    network_config = {
      network = "projects/example-prj/global/networks/vpc-example-prd"
    }
    initial_user = {
      user     = "postgres"
      password = "example-password"
    }
    continuous_backup_config = {
      enabled              = true
      recovery_window_days = 14
    }
    automated_backup_policy = {
      enabled       = true
      location      = "europe-west4"
      backup_window = "1800s"
      weekly_schedule = {
        days_of_week = ["MONDAY"]
        start_times  = [{ hours = 23 }]
      }
      quantity_based_retention = { count = 2 }
    }
    instances = {
      "primary" = {
        instance_id   = "example-app-primary"
        instance_type = "PRIMARY"
        machine_config = { cpu_count = 2 }
      }
      "reads" = {
        instance_type    = "READ_POOL"
        read_pool_config = { node_count = 2 }
      }
    }
    backups = {
      "daily" = {
        backup_id = "example-app-backup"
        location  = "europe-west4"
        type      = "ON_DEMAND"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names. Instance and
  backup outputs are keyed `<cluster key>/<instance|backup key>`.
- AlloyDB clusters are private-IP-only: `network_config.network` requires
  Private Services Access — pair with `gcp/private-service-connect` to
  allocate ranges and create the `servicenetworking.googleapis.com`
  connection. The instance create will hang until the peering exists
  (`depends_on` needed consumer-side for a brand-new connection).
- Pair with `gcp/project-services` (`alloydb.googleapis.com`); this module
  does not enable APIs itself.
- Restore-from-backup (`restore_backup_source`) and PITR
  (`restore_continuous_backup_source`) clusters are deliberately out of
  scope for now — a follow-up addition if needed. BackupDR restore sources
  are skipped too.
- `initial_user.password` is stored in the raw state as plain text — handle
  state security consumer-side (or use the API-side write-only support if
  your provider version has `password_wo`; not exposed here).
- Deleting a SECONDARY instance does not delete it — it abandons it — and
  deleting the secondary cluster requires `deletion_policy = "FORCE"` on
  that cluster. Promotion/upgrade of `cluster_type` and
  `database_version` major versions are irreversible changes.
- AlloyDB access is project IAM + database users (`google_alloydb_user` is
  a deliberate omission from this module; no per-cluster IAM resource
  exists).

## Import

`google_alloydb_cluster` ←
`projects/{project}/locations/{location}/clusters/{cluster_id}`.
`google_alloydb_instance` ←
`projects/{project}/locations/{location}/clusters/{cluster}/instances/{instance_id}`.
`google_alloydb_backup` ←
`projects/{project}/locations/{location}/backups/{backup_id}`.
