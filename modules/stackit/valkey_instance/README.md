# stackit/valkey_instance

Map-keyed module for STACKIT Valkey instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name (validated non-empty). Changing it replaces the instance. |
| `version` | `string` | — | Valkey version (free string — confirm the versions the chosen plan supports against the STACKIT docs). Updates in place. |
| `plan_name` | `string` | — | Plan name; list available plans consumer-side via the `stackit_valkey_plans` data source (validated non-empty). Updates in place. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the instance. |
| `parameters` | `object` | `null` | Service parameters; see the `parameters` object table. See the removal caveat in Notes before editing fields. |

### `parameters` object

All attributes optional; `sgw_acl` is a single comma-separated CIDR string, not a list.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `sgw_acl` | `string` | `null` | Comma-separated list of IP networks in CIDR notation which are allowed to access this instance (validated). Updates in place. |
| `enable_monitoring` | `bool` | `null` | Enables monitoring integration with an Observability instance. Updates in place. |
| `down_after_milliseconds` | `number` | `null` | Milliseconds after which the instance is considered down. Updates in place. |
| `failover_timeout` | `number` | `null` | Failover timeout in milliseconds. Updates in place. |
| `graphite` | `string` | `null` | Graphite server URL (host and port); enables Graphite monitoring. Updates in place. |
| `lazyfree_lazy_eviction` | `string` | `null` | Lazy eviction enablement (`yes` or `no`). Updates in place. |
| `lazyfree_lazy_expire` | `string` | `null` | Lazy expire enablement (`yes` or `no`). Updates in place. |
| `lua_time_limit` | `number` | `null` | Lua scripts time limit in milliseconds. Updates in place. |
| `max_disk_threshold` | `number` | `null` | Maximum disk threshold in MB; the instance is stopped if exceeded. Updates in place. |
| `maxclients` | `number` | `null` | Maximum number of clients. Updates in place. |
| `maxmemory_policy` | `string` | `null` | Policy to handle max memory (e.g. `volatile-lru`, `noeviction`). Updates in place. |
| `maxmemory_samples` | `number` | `null` | Number of samples for the max-memory approximation algorithm. Updates in place. |
| `metrics_frequency` | `number` | `null` | Frequency in seconds at which metrics are emitted. Updates in place. |
| `metrics_prefix` | `string` | `null` | Prefix for emitted metrics (e.g. an API key when using Graphite). Updates in place. |
| `min_replicas_max_lag` | `number` | `null` | Minimum replicas maximum lag. Updates in place. |
| `min_replicas_to_write` | `number` | `null` | Connected replicas required for the primary to accept writes; `0` disables it. Updates in place. |
| `monitoring_instance_id` | `string` | `null` | UUID of the Observability instance to integrate with (validated). Updates in place. |
| `notify_keyspace_events` | `string` | `null` | Keyspace events notification configuration. Updates in place. |
| `repl_backlog_size` | `string` | `null` | Replication backlog size for the cluster. Updates in place. |
| `snapshot` | `string` | `null` | Snapshot configuration. Updates in place. |
| `syslog` | `list(string)` | `null` | Syslog servers (`host:port`) to send logs to. Updates in place. |

There are no TLS parameters on this resource (unlike the deprecated
`stackit_redis_instance`, which has `tls_ciphers`/`tls_ciphersuites`/`tls_protocols`).

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance UUID. |
| `id` | `"{project_id},{region},{instance_id}"` — the import ID. |

No host/port/credentials are exposed here — this instance resource offers
no connection info; credentials come from the `stackit_valkey_credential`
resource.

## Example

```hcl
module "valkey_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/valkey_instance?ref=v2.1.0"

  instances = {
    "app-cache" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app-cache"
      version    = "8"
      plan_name  = "example-plan-name"
      region     = "eu01"
      parameters = {
        sgw_acl           = "10.0.0.0/8"
        enable_monitoring = true
      }
    }
  }
}
```

## Notes

- Valkey is a regular (non-beta) resource in the provider — no
  `enable_beta_resources` or experiments flag is needed.
- Keys are arbitrary unique identifiers, not names — multiple resources
  can share a name, so the key disambiguates them.
- **Renaming a map key destroys and recreates the instance — data-loss
  risk on a cache instance.** The same applies to changing `name`,
  `project_id` or `region`.
- `name`, `project_id` and `region` replace the instance; `version`,
  `plan_name` and all `parameters` fields update in place.
- **`parameters` removal caveat**: parameters are Optional+Computed on
  the provider side — removing a previously configured field from
  config does NOT unset it in the API, and setting a parameter
  attribute to null does not clear it either; to "clear" a value, set a
  new one. Do not expect drift-free removal.
- **`sgw_acl` is a single comma-separated CIDR string** (e.g.
  `"10.0.0.0/8"`), not a list.
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, non-empty name/plan_name, CIDR notation for `sgw_acl`, UUID
  `monitoring_instance_id`) as forward-checking; Valkey-tuning
  parameter values (e.g. `maxmemory_policy`) are left unvalidated — the
  provider does not enumerate valid values.
- Hosts, ports and credentials are not available on this resource.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_valkey_instance` ← `{project_id},{region},{instance_id}`
