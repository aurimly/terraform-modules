# gcp/memorystore

Map-keyed module for Google Cloud Memorystore Redis and Valkey instances.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instances` | `map(object)` | — | Map of instances keyed by an arbitrary unique ID. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Instance name; lowercase letters/digits/hyphens, 1–60 chars, starting and ending with a letter or digit. Validated client-side. |
| `region` | `string` | — | GCP region (shape validated). Immutable; changing forces replacement. |
| `memory_size_gb` | `number` | — | Memory per node, 1–300 GB (validated). In-place but may cause a failover. |
| `redis_version` | `string` | — | One of `REDIS_5_0`, `REDIS_6_X`, `REDIS_7_0`, `REDIS_7_2`, `VALKEY_7_0`, `VALKEY_7_2`, `VALKEY_8_0` (case-sensitive). Required here (the provider defaults to the latest supported); older versions are deprecated API-side. Immovable without version migration — upgrades are in-place, downgrades are rejected. |
| `tier` | `string` | `STANDARD_HA` | One of `BASIC`, `STANDARD_HA` (case-sensitive). |
| `project_id` | `string` | — | Project; defaults to the provider-level project. Format validated. |
| `location_id` | `string` | — | Zone for the primary node (e.g. `europe-west4-a`); GCP picks a zone when unset. |
| `alternative_location_id` | `string` | — | Preferred zone for the replica node on `STANDARD_HA` instances; unused for `BASIC`. |
| `connect_mode` | `string` | — | One of `DIRECT_PEERING`, `PRIVATE_SERVICE_ACCESS` (case-sensitive). |
| `reserved_ip_range` | `string` | — | IP range for the instance; requires `connect_mode = PRIVATE_SERVICE_ACCESS` (validated). Either an allocated-range name (see the `gcp/private-service-connect` pairing below) or a CIDR string (e.g. `10.0.0.0/29`). |
| `secondary_ip_range` | `string` | — | Range for the output replica's address; requires `reserved_ip_range` too (validated). |
| `authorized_network` | `string` | — | VPC network name or self link the instance is connected through. |
| `display_name` | `string` | — | Human-readable display name. |
| `labels` | `map(string)` | `{}` | User labels. |
| `redis_configs` | `map(string)` | `{}` | User-settable Redis parameters (e.g. `maxmemory-policy = "allkeys-lru"`), string => string. |
| `auth_enabled` | `bool` | — | AUTH token authentication; requires `REDIS_6_X` or higher or `VALKEY_*` (validated). |
| `transit_encryption_mode` | `string` | — | One of `DISABLED`, `SERVER_AUTHENTICATION` (case-sensitive). |
| `replica_count` | `number` | — | Replicas per node: 1 for `STANDARD_HA` without read replicas, 1–5 with read replicas enabled (server default 2), 0 for `BASIC` (validated; simplified to 0–5 here). |
| `read_replicas_mode` | `string` | — | One of `READ_REPLICAS_DISABLED`, `READ_REPLICAS_ENABLED` (case-sensitive). |
| `maintenance_policy` | `object` | — | `{day, start_time}`: `day` one of `MONDAY`–`SUNDAY`, `start_time` = `{hours, minutes?}` (UTC; validated). |
| `persistence_config` | `object` | — | `{persistence_mode, rdb_snapshot_period, rdb_snapshot_start_time}`: `persistence_mode` one of `DISABLED`, `RDB` (validated); `rdb_snapshot_period` required with RDB (validated). |
| `deletion_protection` | `bool` | `true` | API-level protection flag — set to `false` explicitly to allow destroy. |

## Outputs

`instance_ids` — map of instance key => full resource path
(`projects/<project>/locations/<region>/instances/<name>`).
`instance_hosts` — map of instance key => instance host IP.
`instance_ports` — map of instance key => instance port.
`instance_current_location_ids` — map of instance key => the zone GCP
actually placed the instance in (may differ from `location_id` when omitted).

## Example

```hcl
instances = {
  "cache" = {
    name           = "example-cache"
    region         = "europe-west4"
    memory_size_gb = 5
    redis_version  = "REDIS_7_0"
    tier           = "STANDARD_HA"
    redis_configs = {
      "maxmemory-policy" = "allkeys-lru"
    }
  }
  "session" = {
    name              = "example-session-store"
    region            = "europe-west4"
    memory_size_gb    = 10
    redis_version     = "VALKEY_7_2"
    auth_enabled      = true
    connect_mode      = "PRIVATE_SERVICE_ACCESS"
    authorized_network = "vpc-example-prd"
    reserved_ip_range = "example-psa-range"
  }
}
```

## Notes

- Keys are arbitrary unique identifiers, not instance names.
- Private connectivity (`connect_mode = PRIVATE_SERVICE_ACCESS`) requires
  Private Services Access: pair with `gcp/private-service-connect` —
  allocate a range and create the `servicenetworking.googleapis.com`
  connection there, then pass its output `allocated_range_names` value to
  `reserved_ip_range`, and pass the VPC to `authorized_network`.
- Pair with `gcp/project-services` (`redis.googleapis.com`) when the project
  does not have the API enabled yet; this module does not enable APIs itself.
- With `auth_enabled`, the AUTH token is fetched separately (GCP CLI/APP;
  it is not exposed by this module).
- Tier and memory-size changes are in-place but can trigger a failover;
  `region` and node placement are immutable.
- Setting `reserved_ip_range`/`secondary_ip_range` without
  `PRIVATE_SERVICE_ACCESS` is rejected here and by the API.
- CMEK (`customer_managed_key`) is out of scope today.

## Import

`google_redis_instance` ←
`projects/{project}/locations/{region}/instances/{name}` (also
`{project}/{region}/{name}`, `{region}/{name}`, and the bare `{name}`).
