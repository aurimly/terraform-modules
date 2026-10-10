# azure/redis

Map-keyed module for Azure Cache for Redis with linked firewall rules, patch
schedules, and geo-replication between the caches of one module call. Each
entry creates one `azurerm_redis_cache` in the named resource group; cache
names are globally unique across all of Azure. Classic Redis only — the
Redis Enterprise SKUs are separate resources entirely and out of scope.

## Destroy semantics (read before using)

- Removing a cache key destroys the cache and everything it holds. Redis is
  memory-state — replacing it is a data wipe, so keep `prevent_destroy`
  in mind for anything holding session or object-cache data.
- Removing a firewall-rule entry deletes the rule only.
- Removing a linked-server entry unlinks the geo-repair pair; the caches
  survive but their replication stops.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `redis_caches` | `map(object)` | — | Map of Redis caches keyed by an arbitrary unique ID. |
| `linked_servers` | `map(object)` | `{}` | Geo-replication links wired between two caches of the same call. |

Plan-time validation: cache name is 2–63 lowercase alphanumerics/hyphens;
`family`/`sku_name` pairing (`C` ↔ Basic/Standard, `P` ↔ Premium) with
capacity ranges per family (C 0–6, P 1–5); `redis_version` `4`/`6`;
`minimum_tls_version` `1.2` only; Premium-only `subnet_id`/`shard_count`/
`replicas_per_master`/AOF/RDB persistence; `shard_count` and
`replicas_per_master` mutually exclusive; `replicas_per_primary` equals
`replicas_per_master` when both are set; no-auth
(`redis_configuration.authentication_enabled = false`) requires `subnet_id`;
`access_keys_authentication_enabled = false` requires Entra auth on;
AOF/RDB enabled requires their storage connection strings; `rdb_backup_
frequency` in the documented set; `zones` entries `1`/`2`/`3`; patch-schedule
weekday/start-hour/maintenance-window shapes; firewall addresses bare IPv4;
tags respecting the 50/512/256 limits; map keys on every level without `.`.

### `redis_caches` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cache name: lowercase alphanumerics/hyphens (validated), globally unique across Azure (the module cannot check — a claimed name fails at apply). Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the cache lives in. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `capacity` | `number` | — | Cache size: 0–6 for family `C`, 1–5 for family `P` (validated). |
| `family` | `string` | — | Pricing group, `C` or `P`, paired to the SKU (validated). |
| `sku_name` | `string` | — | `Basic`, `Standard` or `Premium` (validated). Downgrades force replacement. |
| `redis_version` | `string` | `6` | Major Redis version, `4` or `6` (validated). Version 4 no longer accepts new instances in most regions — use `6`. |
| `non_ssl_port_enabled` | `bool` | `false` | Expose the insecure 6379 port. Keep off unless you know what this unlocks. |
| `minimum_tls_version` | `string` | `1.2` | Minimum TLS version — must be `1.2` (validated; TLS 1.0/1.1 are retired). |
| `public_network_access_enabled` | `bool` | `true` | Public reachability; set `false` when the cache is subnet-only or behind a private endpoint. |
| `access_keys_authentication_enabled` | `bool` | `null` | Keep the access-key auth path on (provider default `true`). Setting `false` requires Entra auth on in `redis_configuration` (validated). Kept null-defaulted in-module — see Notes. |
| `subnet_id` | `string` | `null` | Premium only (validated): full ARM resource ID of an exclusive subnet — it must contain Azure Cache instances only. Changing it forces replacement. |
| `private_static_ip_address` | `string` | `null` | Static IP inside `subnet_id` (implies it — validated). Changing it forces replacement. |
| `shard_count` | `number` | `null` | Premium only (validated): shards on the cluster. Mutually exclusive with `replicas_per_master` (validated). |
| `replicas_per_master` | `number` | `null` | Premium only (validated): replicas per master. Mutually exclusive with `shard_count` (validated); equals `replicas_per_primary` when both are set (validated). |
| `replicas_per_primary` | `number` | `null` | Replicas per primary — equal to `replicas_per_master` when both are set (validated). |
| `tenant_settings` | `map(string)` | `{}` | Tenant settings mapping. |
| `zones` | `list(string)` | `[]` | Availability zones `1`/`2`/`3`, region-dependent. Changing zones forces replacement (see Notes). |
| `redis_configuration` | `object` | `null` | Optional single configuration block — see the object table. |
| `patch_schedule` | `map(object)` | `{}` | Patch windows — `{ day_of_week, start_hour_utc, maintenance_window }`; weekday is a full name (`Monday`…`Sunday`), hour 0–23 UTC, window an ISO 8601 timespan (default `PT5H`). |
| `firewall_rules` | `map(object)` | `{}` | Firewall rules — `{ name, start_ip, end_ip }` with bare IPv4 (validated). |
| `identity` | `object` | `null` | Optional identity block — `{ type, identity_ids }`; the system-assigned principal ID surfaces through `cache_identity_principal_ids`. |
| `tags` | `map(string)` | `{}` | Tags on the cache. Authoritative — a change replaces the whole tag set. |

### `redis_configuration` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `aof_backup_enabled` | `bool` | `null` | AOF persistence — Premium only (validated). Requires `aof_storage_connection_string_0` (validated). |
| `aof_storage_connection_string_0` | `string` | `null` | First storage connection string for AOF. |
| `aof_storage_connection_string_1` | `string` | `null` | Second storage connection string for AOF. |
| `rdb_backup_enabled` | `bool` | `null` | RDB snapshots — Premium only (validated). Requires `rdb_storage_connection_string` (validated). |
| `rdb_backup_frequency` | `number` | `null` | Snapshot interval in minutes: 15, 30, 60, 360, 720 or 1440 (validated). |
| `rdb_backup_max_snapshot_count` | `number` | `null` | Max snapshots kept. |
| `rdb_storage_connection_string` | `string` | `null` | Storage connection string for RDB — see Notes on the API bug. |
| `storage_account_subscription_id` | `string` | `null` | Subscription of the backup storage account when it lives elsewhere. |
| `data_persistence_authentication_method` | `string` | `null` | Auth to storage for persistence: `SAS` or `ManagedIdentity` (validated). |
| `authentication_enabled` | `bool` | `null` | Setting `false` makes the cache unauthenticated — requires `subnet_id` (validated). |
| `active_directory_authentication_enabled` | `bool` | `null` | Entra ID auth; required when access-key auth is disabled (validated). |
| `maxmemory_reserved` | `number` | `null` | MB reserved for non-cache usage (Standard/Premium defaults 50/200). |
| `maxmemory_delta` | `number` | `null` | Max-memory delta (Standard/Premium only). |
| `maxmemory_policy` | `string` | `null` | Eviction policy (default `volatile-lru`). |
| `maxfragmentationmemory_reserved` | `number` | `null` | MB reserved for fragmentation (Standard/Premium only). |
| `notify_keyspace_events` | `string` | `null` | Keyspace notification classes (see the Redis config reference). |

### `linked_servers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `target_cache_key` | `string` | — | Key into `redis_caches` of the cache the link attaches to (the primary side). |
| `linked_cache_key` | `string` | — | Key into `redis_caches` of the other member of the pair. Different from the target (validated). |
| `server_role` | `string` | — | `Primary` or `Secondary` (validated) — the role the linked cache takes in the pair. |

## Outputs

| Name | Description |
|---|---|
| `cache_ids` | Map of cache key => full ARM resource ID. |
| `cache_names` | Map of cache key => cache name. |
| `cache_hostnames` | Map of cache key => the cache hostname — the host connection strings target. |
| `cache_ssl_ports` | Map of cache key => the SSL port. |
| `cache_primary_access_keys` | Map of cache key => primary access key (sensitive). |
| `cache_secondary_access_keys` | Map of cache key => secondary access key (sensitive). |
| `cache_primary_connection_strings` | Map of cache key => primary connection string (sensitive). |
| `cache_secondary_connection_strings` | Map of cache key => secondary connection string (sensitive). |
| `cache_identity_principal_ids` | Map of cache key => system-assigned identity principal ID. |
| `firewall_rule_ids` | Map of `<cache_key>.<rule_key>` => firewall-rule ARM resource ID. |
| `linked_server_ids` | Map of linked-server key => linked-server ARM resource ID. |
| `linked_server_geo_replicated_primary_host_names` | Map of linked-server key => geo-replicated primary hostname. |

## Example

```hcl
redis_caches = {
  "sessions-eu" = {
    name                = "cache-sessions-eu-01"
    resource_group_name = "rg-cache-prod"
    location            = "westeurope"
    capacity            = 2
    family              = "P"
    sku_name            = "Premium"

    subnet_id   = dependency.subnet.outputs.subnet_ids["redis"]
    shard_count = 2

    redis_configuration = {
      rdb_backup_enabled            = true
      rdb_backup_frequency          = 360
      rdb_storage_connection_string = var.redis_backup_conn_string
    }

    patch_schedule = {
      "monday" = {
        day_of_week    = "Monday"
        start_hour_utc = 2
      }
    }

    firewall_rules = {
      "office" = {
        name     = "office"
        start_ip = "203.0.113.10"
        end_ip   = "203.0.113.30"
      }
    }

    tags = {
      env = "prod"
    }
  }
  "sessions-us" = {
    name                = "cache-sessions-us-01"
    resource_group_name = "rg-cache-prod"
    location            = "eastus"
    capacity            = 2
    family              = "P"
    sku_name            = "Premium"
  }
}

linked_servers = {
  "sessions-pair" = {
    target_cache_key = "sessions-eu"
    linked_cache_key = "sessions-us"
    server_role      = "Secondary"
  }
}
```

## Notes

- **Access keys in state**: `cache_primary_access_keys` and
  `cache_secondary_access_keys` are sensitive outputs but still land in
  state. For keyless operation set
  `redis_configuration.active_directory_authentication_enabled = true` and
  `access_keys_authentication_enabled = false` — the module keeps the
  latter null-defaulted because the provider default (`true`) is the safe
  posture and a default flip inside the module would surprise existing
  configs.
- **RDB connection-string API bug**: the Redis API does not return the
  original `rdb_storage_connection_string`, so the provider sees a spurious
  diff on every plan. Add a consumer-side `lifecycle { ignore_changes =
  [redis_configuration[0].rdb_storage_connection_string] }` if you hit it.
- **SKU downgrades force replacement**; upgrades are in-place.
- **Subnet exclusivity**: Premium caches require a subnet that holds Azure
  Cache instances only, and moving between subnets forces replacement —
  size the subnet (up to /24 for the largest families) before the first
  apply.
- **`zones` changes force replacement** too — zone-pinned from the start or
  not all.
- **Geo-replication pairs are one-to-one**: a cache can participate in at
  most one linked server per role; the module does not police that across
  entries (the Azure API rejects the second), and both members must be
  Premium and same size (capacity/family equal — validated here).
- Cache names being globally unique, a claimed name fails at apply — the
  module cannot check at plan.
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.Cache/redis/write` plus the `firewallRules` and
  `linkedServers` children on scope.

## Import

Caches import by ARM ID; firewall rules and linked servers reference the
cache by ARM ID and name:

```
tofu import 'azurerm_redis_cache.cache["sessions-eu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Cache/redis/<name>"
tofu import 'azurerm_redis_firewall_rule.rule["sessions-eu.office"]' "<cache_id>/firewallRules/<rule-name>"
tofu import 'azurerm_redis_linked_server.linked_server["sessions-pair"]' "<target-cache-id>/linkedServers/<linked-cache-name>"
```
