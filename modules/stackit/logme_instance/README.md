# stackit/logme_instance

Map-keyed module for STACKIT LogMe instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `project_id` | `string` | — | STACKIT project UUID the instance is created in (validated). Changing it replaces the instance. |
| `name` | `string` | — | Instance name (validated non-empty). Changing it replaces the instance. |
| `version` | `string` | — | LogMe version (free string — confirm the versions the chosen plan supports against the STACKIT docs). Updates in place. |
| `plan_name` | `string` | — | Plan name; list available plans consumer-side via the `stackit_logme_plans` data source (validated non-empty). Updates in place. |
| `region` | `string` | provider region | Resource region. If unset, the provider's configured region is used; a region must be set in one of the two places. Changing it replaces the instance. |
| `parameters` | `object` | `null` | Service parameters; see the `parameters` object table. See the removal caveat in Notes before editing fields. |

### `parameters` object

All attributes optional. `sgw_acl` is a single comma-separated CIDR string, not a list.

| Attribute | Type | Default | Description |
|---|---|---|---|
| `sgw_acl` | `string` | `null` | Service Gatekeeper ACL as a comma-separated list of IPv4 CIDRs the instance is reachable from (validated). Updates in place. |
| `enable_monitoring` | `bool` | `null` | Enables monitoring integration with an Observability instance. Updates in place. |
| `graphite` | `string` | `null` | Graphite host for metrics export (`host:port`). Updates in place. |
| `max_disk_threshold` | `number` | `null` | Maximum disk threshold in **megabytes** before throttling (per STACKIT docs — different from some sibling services which use another unit). Updates in place. |
| `metrics_frequency` | `number` | `null` | Metrics export frequency in seconds. Updates in place. |
| `metrics_prefix` | `string` | `null` | Prefix for exported metric names. Updates in place. |
| `monitoring_instance_id` | `string` | `null` | UUID of the Observability instance to integrate with (validated). Updates in place. |
| `java_heapspace` | `number` | `null` | JVM heap space in MB. Updates in place. |
| `java_maxmetaspace` | `number` | `null` | JVM max metaspace in MB. Updates in place. |
| `ism_deletion_after` | `string` | `null` | ISM deletion window: integer followed by `s`, `m`, `h` or `d` (e.g. `14d`; validated). Updates in place. |
| `ism_jitter` | `number` | `null` | ISM jitter (0..1 fraction). Updates in place. |
| `ism_job_interval` | `number` | `null` | ISM job interval in minutes. Updates in place. |
| `fluentd_tcp` | `number` | `null` | Fluentd TCP port. Updates in place. |
| `fluentd_udp` | `number` | `null` | Fluentd UDP port. Updates in place. |
| `fluentd_tls` | `number` | `null` | Fluentd TLS port. Updates in place. |
| `fluentd_tls_ciphers` | `string` | `null` | Fluentd TLS cipher suites. Updates in place. |
| `fluentd_tls_min_version` | `string` | `null` | Fluentd TLS minimum version. Updates in place. |
| `fluentd_tls_max_version` | `string` | `null` | Fluentd TLS maximum version. Updates in place. |
| `fluentd_tls_version` | `string` | `null` | Fluentd TLS version. Updates in place. |
| `opensearch_tls_ciphers` | `list(string)` | `null` | OpenSearch TLS cipher suites to allow. Updates in place. |
| `opensearch_tls_protocols` | `list(string)` | `null` | OpenSearch TLS protocol versions to allow (e.g. `TLSv1.2`). Updates in place. |
| `syslog` | `list(string)` | `null` | Syslog endpoints. Updates in place. |

## Outputs

`instances` — map of instance key => object:

| Attribute | Description |
|---|---|
| `instance_id` | Instance UUID. |
| `plan_id` | Plan UUID the instance runs on. |
| `dashboard_url` | LogMe dashboard URL. |
| `id` | `"{project_id},{region},{instance_id}"` — the import ID. |

Credentials for the instance come from stackit/logme_credential.

## Example

```hcl
module "logme_instance" {
  source = "git::ssh://git@github.com/example/terraform-modules.git//modules/stackit/logme_instance?ref=v2.2.0"

  instances = {
    "app-logs" = {
      project_id = "12345678-1234-1234-1234-123456789012"
      name       = "example-app-logs"
      version    = "2.5"
      plan_name  = "logme-small-replica"
      region     = "eu01"
      parameters = {
        sgw_acl            = "10.0.0.0/8,192.168.0.0/16"
        enable_monitoring  = true
        ism_deletion_after = "14d"
      }
    }
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not names — multiple resources
  can share a name, so the key disambiguates them.
- **Renaming a map key destroys and recreates the instance — data-loss
  risk on a logging service.** The same applies to changing `name`,
  `project_id` or `region`.
- `name`, `project_id` and `region` replace the instance; `version`,
  `plan_name` and all `parameters` fields update in place.
- **`parameters` removal caveat**: parameters are Optional+Computed on
  the provider side — removing a previously configured field from
  config does NOT unset it in the API, and setting a parameter
  attribute to null does not clear it either; to "clear" a value, set a
  new one. Do not expect drift-free removal.
- **`sgw_acl` is a single comma-separated CIDR string** (e.g.
  `"10.0.0.0/8,192.168.0.0/16"`), not a list.
- Eventual consistency: the plans and parameters accepted depend on the
  STACKIT offering at apply time; plan-time validations here mirror the
  provider's plan-time validators (UUIDs, non-empty name/plan_name,
  CIDR notation for `sgw_acl`, UUID `monitoring_instance_id`,
  `ism_deletion_after` unit format) as forward-checking.
- Credentials (`username`/`password`) are not available on this
  resource — manage them via stackit/logme_credential.
- The provider floor `>= 0.114.0` is aligned across all stackit modules
  to the latest provider release the modules are tested against; no
  behavior in this module requires anything newer.
- Provider authentication is configured at the consumer's unit level.

## Import

`stackit_logme_instance` ← `{project_id},{region},{instance_id}`

Upstream docs note: the provider doc import example and the `id`
attribute agree on the 3-part ID — both forms shown upstream are the
same.
