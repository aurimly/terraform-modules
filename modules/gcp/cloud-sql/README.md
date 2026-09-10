# gcp/cloud-sql

Map-keyed module for Google Cloud SQL PostgreSQL and MySQL instances with
optional plain read replicas. Databases and users are out of scope (Google
SQL Server support too).

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance id; up to 98 lowercase letters, digits or hyphens (validated). Immutable; changing forces replacement. |
| `database_version` | `string` | — | `POSTGRES_<n>` or `MYSQL_<n[_n]>` (e.g. `POSTGRES_16`, `MYSQL_8_0`); shape-validated, not a fixed list. Immutable; changing forces replacement. Replicas inherit it from the primary. |
| `region` | `string` | — | GCP region (shape validated). Immutable; changing forces replacement. |
| `tier` | `string` | — | Machine type, e.g. `db-custom-2-7680`, `db-f1-micro` (shape validated). Changing it updates in place but restarts the instance. |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `edition` | `string` | — | One of `ENTERPRISE`, `ENTERPRISE_PLUS` (case-sensitive). Immutable; changing forces replacement. |
| `deletion_protection` | `bool` | `true` | Terraform-level protection flag — set to `false` explicitly to allow destroy. |
| `deletion_policy` | `string` | — | One of `DELETE`, `PREVENT`, `ABANDON` (case-sensitive). `ABANDON` removes the instance from Terraform state without deleting it. |
| `availability_type` | `string` | — | One of `ZONAL`, `REGIONAL` (case-sensitive). |
| `disk_type` | `string` | — | One of `PD_SSD`, `PD_HDD`, `HYPERDISK_BALANCED` (case-sensitive). |
| `disk_size` | `number` | — | Provisioned data disk size, GB. Growing updates in place. |
| `disk_autoresize` | `bool` | — | Enable disk auto-resize. |
| `disk_autoresize_limit` | `number` | — | Upper bound for auto-resize, GB; only meaningful with `disk_autoresize`. |
| `root_password` | `string` | — | MySQL root password; must not be set for `POSTGRES_*` (validated). |
| `database_flags` | `list(object)` | `[]` | MySQL/PostgreSQL flags as `{name, value}`; both strings. |
| `labels` | `map(string)` | `{}` | User labels. |
| `backup_configuration` | `object` | — | Presence enables backups; see `backup_configuration` object table. |
| `ip_configuration` | `object` | — | Presence enables connectivity options; see `ip_configuration` object table. |
| `maintenance_window` | `object` | — | `{day, hour, update_track}`: day 1–7 (Monday–Sunday), hour 0–23 (UTC), `update_track` one of `canary`, `week5`, `stable` (all validated). |
| `insights_config` | `object` | — | `{query_insights_enabled, query_string_length, record_application_tags, record_client_address}`. Scaled `query_plans_per_minute` is out of scope. |
| `replicas` | `map(object)` | `{}` | Read replicas keyed by an arbitrary unique ID; see `replicas` object table. Keys are `instance_key/replica_key` composed in the outputs. |

### `backup_configuration` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | — | Turn on automated backups; required before point-in-time recovery can be enabled. |
| `start_time` | `string` | — | 24-hour `HH:mm` backup window start (validated). |
| `point_in_time_recovery_enabled` | `bool` | — | Point-in-time recovery; the durable change-logs backing it are `binary_log_enabled` for MySQL and built in for PostgreSQL, so set `binary_log_enabled` too when using PITR on MySQL. |
| `binary_log_enabled` | `bool` | — | MySQL binary log; required for MySQL PITR. |
| `retained_backups` | `number` | — | Number of backups to retain (maps to `backup_retention_settings.retained_backups`; validated positive). |
| `location` | `string` | — | Region for the backup (e.g. `us` for multi-region). |

### `ip_configuration` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ipv4_enabled` | `bool` | — | Whether public IPv4 connectivity is on. Public IP stays on by default server-side. |
| `private_network` | `string` | — | VPC network self link to attach the instance via Private Services Access — see Notes. |
| `ssl_mode` | `string` | — | One of `ALLOW_UNENCRYPTED_AND_ENCRYPTED`, `ENCRYPTED_ONLY`, `TRUSTED_CLIENT_CERTIFICATE_REQUIRED` (case-sensitive). |
| `allocated_ip_range` | `string` | — | Name of the PSA-allocated range to use for the private IP; only allowed with `private_network` (validated). |
| `authorized_networks` | `list(object)` | `[]` | Public-IP allowlist entries as `{value, name?}` (CIDR). |

### `replicas` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Replica instance id; same shape as `instances.name` (validated). Immutable. |
| `region` | `string` | — | Replica region (shape validated). |
| `tier` | `string` | — | Replica machine type (shape validated). |
| `availability_type` | `string` | — | One of `ZONAL`, `REGIONAL` (case-sensitive). |
| `disk_type` | `string` | — | As `instances.disk_type`. |
| `disk_size` | `number` | — | As `instances.disk_size`. |
| `disk_autoresize` | `bool` | — | As `instances.disk_autoresize`. |
| `disk_autoresize_limit` | `number` | — | As `instances.disk_autoresize_limit`. |
| `database_flags` | `list(object)` | `[]` | As `instances.database_flags`. |
| `ip_configuration` | `object` | — | Same shape as `instances.ip_configuration`. |
| `deletion_protection` | `bool` | `true` | Terraform-level protection flag for the replica. |

## Outputs

`instance_names` — map of instance key => instance name.
`instance_connection_names` — map of instance key =>
`<project>:<region>:<instance>` for Cloud Run/GKE connectors.
`instance_self_links` — map of instance key => instance self link.
`instance_ip_addresses` — map of instance key =>
`{first_ip_address, private_ip_address, public_ip_address}`; nulls where not
enabled (private IP requires PSA).
`replica_names` / `replica_connection_names` — maps of
`"<instance key>/<replica key>"` => replica name / replica connection name.

## Example

```hcl
instances = {
  "app" = {
    name             = "example-app-db"
    database_version = "POSTGRES_16"
    region           = "europe-west4"
    tier             = "db-custom-2-7680"
    edition          = "ENTERPRISE"
    availability_type = "REGIONAL"
    backup_configuration = {
      enabled                         = true
      start_time                      = "01:00"
      point_in_time_recovery_enabled  = true
      retained_backups                = 7
    }
    ip_configuration = {
      ipv4_enabled    = false
      private_network = "vpc-example-prd"
      authorized_networks = [
        { name = "office", value = "198.51.100.0/24" },
      ]
    }
    replicas = {
      "dr" = {
        name   = "example-app-db-replica"
        region = "europe-west1"
        tier   = "db-custom-2-7680"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not resource names.
- Private IP (`ip_configuration.private_network`) requires Private Services
  Access: pair with `gcp/private-service-connect` — allocate ranges and
  create the `servicenetworking.googleapis.com` connection there, then pass
  its network and optionally the range name to `allocated_ip_range`
  (`allocated_ip_range` requires `private_network`, validated). The first
  peering must exist before the first private-IP instance is created.
- Pair with `gcp/project-services` (`sqladmin.googleapis.com`); this module
  does not enable APIs itself.
- `deletion_protection` is the Terraform-side flag; the API-level
  `settings.deletion_protection_enabled` is deliberately not exposed — use a
  server-side org policy for cross-surface protection instead.
- Replicas are plain cross-region read replicas (`master_instance_name`
  wiring only); failover/external-replica `replica_configuration` is out of
  scope. Replicas inherit `database_version` and the project from the
  primary; replicas do not set `labels` — labeling happens on the primary
  (and API-side org policies) only.
- `name`, `region`, `database_version` and `edition` force replacement;
  `tier` and `availability_type` update in place but restart the instance.
  SQL Server versions and databases/users are out of scope.

## Import

`google_sql_database_instance` ←
`projects/{project}/instances/{name}` (also `{project}/{name}` and the bare
`{name}`; replicas import the same way).
