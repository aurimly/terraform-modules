# stackit/mariadb_instance

Map-keyed module for STACKIT MariaDB instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name (validated non-empty). Changing it replaces the instance. |
| `version` | `string` | — | MariaDB version (e.g. `10.11`, free string — confirm the versions the chosen plan supports against the STACKIT docs). Updates in place. |
| `plan_name` | `string` | — | Plan name; list available plans consumer-side via the `stackit_mariadb_plans` data source (validated non-empty). Updates in place. |
| `region` | `string` | `null` | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the instance. |
| `parameters` | `object` | `null` | Service parameters; see the `parameters` object table. See the removal caveat in Notes before editing fields. |

### `parameters` object

All attributes optional; `sgw_acl` is a single comma-separated CIDR string, not a list.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `sgw_acl` | `string` | `null` | Service Gatekeeper ACL as a comma-separated list of IPv4 CIDRs the instance is reachable from (validated). Updates in place. |
| `enable_monitoring` | `bool` | `null` | Enables monitoring integration with an Observability instance. Updates in place. |
| `graphite` | `string` | `null` | Graphite host for metrics export. Updates in place. |
| `max_disk_threshold` | `number` | `null` | Maximum disk size in gigabytes before throttling (per STACKIT docs — confirm the unit against the current STACKIT documentation). Updates in place. |
| `metrics_frequency` | `number` | `null` | Metrics export frequency in seconds. Updates in place. |
| `metrics_prefix` | `string` | `null` | Prefix for exported metric names. Updates in place. |
| `monitoring_instance_id` | `string` | `null` | UUID of the Observability instance to integrate with (validated). Does not support Observability-Monitoring-Starter plan instances. Updates in place. |
| `syslog` | `list(string)` | `null` | Syslog endpoints. Updates in place. |

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance UUID. |
| `id` | `"{project_id},{region},{instance_id}"` — the import ID. |

No host/port/credentials are exposed here — this instance resource offers
no connection info; user credentials come from stackit/mariadb_credential.

## Example

```hcl
module "mariadb_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/mariadb_instance?ref=v2.1.0"

  instances = {
    "app-db" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app-db"
      version    = "10.11"
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

- Keys are arbitrary unique identifiers, not names — multiple resources
  can share a name, so the key disambiguates them.
- **Renaming a map key destroys and recreates the instance — data-loss
  risk on a database instance.** The same applies to changing `name`,
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
- `parameters.monitoring_instance_id` does not support
  Observability-Monitoring-Starter plan instances (per STACKIT docs).
- Plan-time validations mirror the provider's plan-time validators
  (UUIDs, non-empty name/plan_name, CIDR notation for `sgw_acl`, UUID
  `monitoring_instance_id`) as forward-checking — it references the
  provider-defined plan properties and rejects only configurations
  that would already fail at apply.
- Hosts, ports and credentials are not available on this resource —
  manage them via stackit/mariadb_credential.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_mariadb_instance` ← `{project_id},{region},{instance_id}`
