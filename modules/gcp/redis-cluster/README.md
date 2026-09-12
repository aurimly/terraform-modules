# gcp/redis-cluster

Map-keyed module for Google Cloud Memorystore for Redis Cluster instances
(`google_memorystore_instance`). For the basic/HA Memorystore product see
`gcp/memorystore`.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance ID; lowercase letters/digits/hyphens, 4–63 chars, starting and ending with a letter or digit. Validated client-side. Maps to `instance_id`. |
| `location` | `string` | — | GCP region (shape validated). Immutable; changing forces replacement. |
| `shard_count` | `number` | — | Number of shards, at least 1 (validated); the API-side maximum depends on node type and region. |
| `node_type` | `string` | — | One of `SHARED_CORE_NANO`, `CUSTOM_PICO`, `CUSTOM_MICRO`, `CUSTOM_MINI`, `HIGHMEM_MEDIUM`, `HIGHCPU_MEDIUM`, `HIGHMEM_XLARGE`, `STANDARD_SMALL`, `STANDARD_LARGE`, `HIGHMEM_2XLARGE` (case-sensitive). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `engine_version` | `string` | — | Engine version (e.g. `REDIS_7_0`, `VALKEY_7_2`); API-defaulted when omitted. |
| `engine_configs` | `map(string)` | `{}` | User-provided engine configuration (e.g. `maxmemory-policy = "volatile-ttl"`). |
| `labels` | `map(string)` | `{}` | User labels. |
| `replica_count` | `number` | — | Replica nodes per shard; API-defaulted when omitted. |
| `authorization_mode` | `string` | — | One of `AUTH_DISABLED`, `IAM_AUTH` (case-sensitive). Immutable; API-defaulted when omitted. |
| `transit_encryption_mode` | `string` | — | One of `TRANSIT_ENCRYPTION_DISABLED`, `SERVER_AUTHENTICATION` (case-sensitive). Immutable; API-defaulted when omitted. |
| `deletion_protection` | `bool` | `true` | API-level protection flag (`deletion_protection_enabled`) — set to `false` explicitly to allow destroy. Distinct from the provider-level `deletion_policy` (DELETE/ABANDON/PREVENT), which this module does not expose. |
| `zone_distribution_config` | `object` | — | `{mode, zone}`: `mode` one of `MULTI_ZONE`, `SINGLE_ZONE` (validated); `zone` required with `SINGLE_ZONE` (validated), ignored for `MULTI_ZONE`. Immutable. |
| `maintenance_policy` | `object` | — | `{day, start_time}`: `day` one of `MONDAY`–`SUNDAY`, `start_time` = `{hours, minutes?}` (UTC; validated). |
| `desired_auto_created_endpoints` | `list(object)` | — | Auto-created PSC endpoints: `{network, project_id}` — both required (validated). Immutable; requires a service connection policy (see Notes). |

## Outputs

`instance_ids` — map of instance key => full resource path
(`projects/<project>/locations/<location>/instances/<name>`).
`instance_endpoints` — map of instance key => list of
`{ip_address, port, connection_type}` from the auto-created PSC
connections; empty when none exist.
`instance_states` — map of instance key => state (`CREATING`, `ACTIVE`,
`UPDATING`, `DELETING`).
`instance_uids` — map of instance key => system-assigned unique ID.

## Example

```hcl
instances = {
  "cache" = {
    name        = "example-cache"
    location    = "europe-west4"
    shard_count = 3
    node_type   = "SHARED_CORE_NANO"
    engine_configs = {
      "maxmemory-policy" = "volatile-ttl"
    }
    maintenance_policy = {
      day = "MONDAY"
      start_time = {
        hours = 2
      }
    }
    desired_auto_created_endpoints = [
      {
        network    = "projects/example-prj/global/networks/vpc-example-prd"
        project_id = "example-prj"
      }
    ]
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not instance names.
- `desired_auto_created_endpoints` requires Private Service Connect
  automation: create a service connection policy for service class
  `gcp-memorystore` in the same region with a /29 subnet in the consumer
  network (e.g. via `google_network_connectivity_service_connection_policy`),
  and make sure it is applied before this instance is created.
- Pair with `gcp/project-services` (`redis.googleapis.com`) when the
  project does not have the API enabled yet; this module does not enable
  APIs itself.
- `zone_distribution_config`, `authorization_mode`,
  `transit_encryption_mode` and `desired_auto_created_endpoints` are
  immutable; `engine_version`, `node_type`, `replica_count` and
  `shard_count` can be updated in place.
- CMEK (`kms_key`), persistence, automated backups, cross-instance
  replication and customer-managed CA are out of scope today.

## Import

`google_memorystore_instance` ←
`projects/{project}/locations/{location}/instances/{name}` (also
`{project}/{location}/{name}` and `{location}/{name}`).
