# azure/cosmos-db

Map-keyed module for Cosmos DB accounts with nested SQL databases and
containers (and optional Mongo databases and collections). Each entry
creates one `azurerm_cosmosdb_account` in the named resource group; account
names host the `<name>.documents.azure.com` endpoint and are globally unique
across all of Azure. Child resources wire into the account resources this
module creates itself — no account-ID plumbing on the consumer side.

## Destroy semantics (read before using)

- Removing an account key destroys the account and everything on it —
  databases, containers, collections and all stored data. Free tier or not:
  the data does not survive.
- Removing a database/collection entry deletes that database and its
  children; container entries delete only the container.
- `geo_location` and `consistency_policy` changes re-provision regions — see
  Notes before touching a live account.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cosmosdb_accounts` | `map(object)` | — | Map of Cosmos DB accounts keyed by an arbitrary unique ID. |

Plan-time validation: account name 3–44 (lowercase, no edge hyphens);
`offer_type` Standard; `kind`/`mongo_server_version` pairing (Mongo settings
need `kind = "MongoDB"`); `consistency_policy` level enum with
BoundedStaleness bounds and none elsewhere; geo_location with exactly one
failover_priority 0, unique contiguous priorities; serverless
(`EnableServerless`) rejecting throughput/autoscale everywhere; throughput
multiples of 100 in 400–1,000,000 RU/s, autoscale multiples of 1000 in
1,000–1,000,000 RU/s, mutually exclusive; restore mode pairing with
Continuous backup; backup Continuous/Periodic argument split with bounds;
CMK requiring identity; `capacity` limits; analytical storage schema enum;
indexing `/*` catch-all and composite ordering rules; conflict-resolution
mode/argument pairing; CORS methods and cache age; `default_identity_type`
forms; subnet rule ARM IDs; tags respecting the 50/512/256 limits; map keys
on every level without `.`; Mongo children only on Mongo accounts; child
name uniqueness per parent.

### `cosmosdb_accounts` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Account name: 3–44 lowercase alphanumerics/hyphens (validated), globally unique — it is the endpoint host. Immutable — changing it forces replacement. |
| `resource_group_name` | `string` | — | Resource group the account lives in. |
| `location` | `string` | — | Azure region hosting the primary write region (match `geo_location[failover_priority == 0].location` — see Notes). Immutable — forces replacement. |
| `offer_type` | `string` | `Standard` | The only offer type the API accepts today (validated). |
| `kind` | `string` | `GlobalDocumentDB` | `GlobalDocumentDB`, `MongoDB` or `Parse` (validated). Immutable — forces replacement. |
| `mongo_server_version` | `string` | `null` | Mongo protocol version (7.0, 6.0, 5.0, 4.2, 4.0, 3.6, 3.2) — MongoDB kind only (validated). |
| `minimal_tls_version` | `string` | `Tls12` | The only accepted value anymore (validated against `Tls12`). |
| `free_tier_enabled` | `bool` | `false` | First free-tier account in the subscription — changing later forces replacement (the module cannot check the one-per-subscription rule; see Notes). |
| `analytical_storage_enabled` | `bool` | `false` | Enable analytical storage. Toggling it forces replacement (see Notes). |
| `automatic_failover_enabled` | `bool` | `null` | Failover write regions automatically on outage. |
| `multiple_write_locations_enabled` | `bool` | `null` | Multi-region writes (pairs with Session or stronger consistency). |
| `partition_merge_enabled` | `bool` | `null` | Partition merge feature. |
| `burst_capacity_enabled` | `bool` | `null` | Burst capacity feature. |
| `public_network_access_enabled` | `bool` | `true` | Public endpoint reachability — pair with `virtual_network_rule`/network ACL posture. |
| `is_virtual_network_filter_enabled` | `bool` | `null` | Apply the subnet allowlist (the `virtual_network_rule` map). |
| `local_authentication_enabled` | `bool` | `true` | Key-based auth; `false` restricts to AAD/MSI exclusively. |
| `access_key_metadata_writes_enabled` | `bool` | `true` | Metadata writes through account keys. |
| `network_acl_bypass_for_azure_services` | `bool` | `null` | Trusted Azure services bypass the ACLs. |
| `network_acl_bypass_ids` | `list(string)` | `null` | ARM IDs of resources (e.g. Fabric) allowed to bypass the ACLs. |
| `ip_range_filter` | `list(string)` | `null` | CIDR allowlist for the public endpoint (e.g. `["203.0.113.0/24"]`). |
| `default_identity_type` | `string` | `null` | `FirstPartyIdentity`, `SystemAssignedIdentity` or `UserAssignedIdentity=<ARM ID>` (validated) — the identity reaching Key Vault. |
| `key_vault_key_id` | `string` | `null` | Versionless CMK key URI — requires `identity` (validated). Changing it forces replacement. |
| `capabilities` | `map(object)` | `{}` | Named capabilities (`{ name }`) — e.g. `EnableServerless`, `EnableMongo`, `MongoDBv3.4` (which requires `EnableMongo`, validated). Immutable once set. |
| `consistency_policy` | `object` | — | `{ consistency_level, max_interval_in_seconds, max_staleness_prefix }` — level from BoundedStaleness/Eventual/Session/Strong/ConsistentPrefix; BoundedStaleness requires the bounds (interval 5–86400, prefix 10–2147483647), others take neither (all validated). |
| `geo_location` | `map(object)` | — | Replication regions — `{ location, failover_priority, zone_redundant }`; exactly one entry with priority 0 (validated), priorities unique and contiguous (validated); `location` matching the account `location` for priority 0 as typical. |
| `virtual_network_rule` | `map(object)` | `{}` | Subnet allowlist — `{ id, ignore_missing_vnet_service_endpoint }` with full ARM subnet IDs (validated). |
| `analytical_storage` | `object` | `null` | `{ schema_type }` — `FullFidelity` or `WellDefined` (validated). |
| `capacity` | `object` | `null` | `{ total_throughput_limit }` — -1 (no limit) or 0–1,000,000 RU/s (validated). |
| `backup` | `object` | `null` | `{ type, tier, interval_in_minutes, retention_in_hours, storage_redundancy }` — Continuous takes only the tier, Periodic the rest with documented bounds (validated); see Notes on the one-way Periodic→Continuous move. |
| `cors_rule` | `object` | `null` | `{ allowed_headers, allowed_methods, allowed_origins, exposed_headers, max_age_in_seconds }` — methods from the standard verbs (validated), max age 1–2147483647 (validated). |
| `create_mode` | `string` | `Default` | `Default` or `Restore` (restore pairs with Continuous backup + the `restore` block — both validated). Immutable — forces replacement. |
| `restore` | `object` | `null` | `{ source_cosmosdb_account_id, restore_timestamp_in_utc, database }` — the source is a restorableDatabaseAccounts ARM ID; `database` is a map of `{ name, collection_names }` to filter what restores. |
| `identity` | `object` | `null` | Optional identity block — `{ type, identity_ids }`; required for CMK (validated). |
| `sql_databases` | `map(object)` | `{}` | SQL API databases — see the object table. |
| `mongo_databases` | `map(object)` | `{}` | Mongo API databases — see the object table (MongoDB kind only, validated). |
| `tags` | `map(string)` | `{}` | Tags on the account. Authoritative — a change replaces the whole tag set. |

### `sql_databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database name — unique within the account (validated). Immutable — forces replacement. |
| `throughput` | `number` | `null` | Manual RU/s — multiple of 100 in 400–1,000,000 (validated). Set at creation only; later changes need member-level resources or a replace (see Notes). |
| `autoscale_settings` | `object` | `null` | `{ max_throughput }` — multiple of 1000 in 1,000–1,000,000 RU/s (validated). Mutually exclusive with `throughput` (validated). |
| `containers` | `map(object)` | `{}` | Containers — see the object table. |

### `sql_databases.containers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Container name — unique within its database (validated). Immutable — forces replacement. |
| `partition_key_paths` | `list(string)` | — | Partition-key paths (`["/customerId"]`).Immutable — forces replacement. |
| `partition_key_kind` | `string` | `Hash` | `Hash` or `MultiHash`. Immutable — forces replacement. |
| `partition_key_version` | `number` | `null` | 1 or 2 — set 2 for large partition keys. |
| `throughput` | `number` | `null` | Manual RU/s — same rules as databases (validated). |
| `autoscale_settings` | `object` | `null` | `{ max_throughput }` — same rules as databases (validated). |
| `default_ttl` | `number` | `null` | Container TTL in seconds; -1 means no default expiry. |
| `analytical_storage_ttl` | `number` | `null` | Synapse-link TTL in seconds. |
| `unique_key` | `map(object)` | `{}` | Uniqueness constraints — `{ paths }` each; immutable, forces replacement. |
| `indexing_policy` | `object` | `null` | `{ indexing_mode, included_path, excluded_path, composite_index, spatial_index }` — either included or excluded must carry the `/*` catch-all (validated); composite entries `{ path, order }` with Ascending/Descending (validated). |
| `conflict_resolution_policy` | `object` | `null` | `{ mode, conflict_resolution_path, conflict_resolution_procedure }` — LastWriterWins pairs with the path, Custom with the procedure (validated); immutable, forces replacement. |

### `mongo_databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database name — unique within the account (validated). Immutable — forces replacement. |
| `throughput` | `number` | `null` | Manual RU/s — same rules as SQL databases (validated). |
| `autoscale_settings` | `object` | `null` | `{ max_throughput }` — same rules (validated). |
| `collections` | `map(object)` | `{}` | Collections — see the object table. |

### `mongo_databases.collections` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Collection name — unique within its database (validated). Immutable — forces replacement. |
| `shard_key` | `string` | `null` | Shard key name. Immutable — forces replacement. |
| `default_ttl_seconds` | `number` | `null` | TTL in seconds. |
| `analytical_storage_ttl` | `number` | `null` | Synapse-link TTL in seconds. |
| `throughput` | `number` | `null` | Manual RU/s — same rules (validated). |
| `autoscale_settings` | `object` | `null` | `{ max_throughput }` — same rules (validated). |
| `index` | `map(object)` | `{}` | Index definitions — `{ keys, unique }`; shard keys must be unique indexes at the API. |

## Outputs

| Name | Description |
|---|---|
| `account_ids` | Map of account key => full ARM resource ID. |
| `account_names` | Map of account key => account name. |
| `account_endpoints` | Map of account key => the account endpoint. |
| `account_write_endpoints` | Map of account key => list of write endpoints. |
| `account_read_endpoints` | Map of account key => list of read endpoints. |
| `account_primary_keys` | Map of account key => primary key (sensitive). |
| `account_secondary_keys` | Map of account key => secondary key (sensitive). |
| `account_primary_readonly_keys` | Map of account key => primary read-only key (sensitive). |
| `account_primary_sql_connection_strings` | Map of account key => primary SQL connection string (sensitive). |
| `account_primary_mongodb_connection_strings` | Map of account key => primary MongoDB connection string (sensitive). |
| `account_identity_principal_ids` | Map of account key => system-assigned identity principal ID. |
| `sql_database_names` | Map of `<account_key>.<db_key>` => SQL database name. |
| `sql_database_ids` | Map of `<account_key>.<db_key>` => SQL database ARM resource ID. |
| `sql_container_names` | Map of `<account_key>.<db_key>.<container_key>` => SQL container name. |
| `sql_container_ids` | Map of `<account_key>.<db_key>.<container_key>` => SQL container ARM resource ID. |
| `mongo_database_names` | Map of `<account_key>.<db_key>` => Mongo database name. |
| `mongo_database_ids` | Map of `<account_key>.<db_key>` => Mongo database ARM resource ID. |
| `mongo_collection_names` | Map of `<account_key>.<db_key>.<collection_key>` => Mongo collection name. |
| `mongo_collection_ids` | Map of `<account_key>.<db_key>.<collection_key>` => Mongo collection ARM resource ID. |

## Example

```hcl
cosmosdb_accounts = {
  "orders-eu" = {
    name                = "cosmos-orders-eu-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"

    multiple_write_locations_enabled = false
    automatic_failover_enabled       = true

    capabilities = {
      "vector" = {
        name = "EnableNoSQLVectorSearch"
      }
    }

    consistency_policy = {
      consistency_level       = "BoundedStaleness"
      max_interval_in_seconds = 300
      max_staleness_prefix    = 100000
    }

    geo_location = {
      "primary" = {
        location          = "westeurope"
        failover_priority = 0
      }
      "secondary" = {
        location          = "northeurope"
        failover_priority = 1
        zone_redundant    = true
      }
    }

    backup = {
      type                = "Periodic"
      interval_in_minutes = 240
      retention_in_hours  = 24
    }

    sql_databases = {
      "orders" = {
        name = "orders"
        containers = {
          "items" = {
            name                = "items"
            partition_key_paths = ["/customerId"]
            autoscale_settings = {
              max_throughput = 4000
            }
            indexing_policy = {
              excluded_path = {
                "payload" = {
                  path = "/payload/*"
                }
              }
              included_path = {
                "all" = {
                  path = "/*"
                }
              }
            }
            default_ttl = -1
          }
          "receipts" = {
            name                  = "receipts"
            partition_key_paths   = ["/receiptId"]
            throughput            = 400
            unique_key = {
              "bucket" = {
                paths = ["/bucket", "/nonce"]
              }
            }
          }
        }
      }
    }

    tags = {
      env = "prod"
    }
  }
}
```

## Notes

- **Keys and connection strings in state**: the key and connection-string
  outputs are sensitive but still land in state. For keyless operation set
  `local_authentication_enabled = false` and manage SQL RBAC with
  `azurerm_cosmosdb_sql_role_assignment` (out of this module's scope —
  use it consumer-side to grant Entra principals data-plane access).
- **Free tier**: one account per subscription — the module cannot check the
  subscription state at plan, the API rejects the second attempt. Also
  `free_tier_enabled` forces replacement on toggle both ways.
- **Serverless**: with the `EnableServerless` capability no throughput or
  autoscale settings may appear on any database, container, or collection —
  validated here; the API rejects them at apply otherwise.
- **Throughput immutability after creation**: setting, raising or removing
  `throughput`/`autoscale_settings` on a database after the first apply
  needs the parent destroyed-and-reapplied at the Azure level (the provider
  errors); production configs generally prefer autoscale up front. Read the
  provider docs note before deciding to move RU/s on live databases.
- **Backup mode is one-way Periodic→Continuous**; Continuous (and tier)
  switches are supported on new tiers, going back to Periodic is not.
  `restore` mode accounts must use Continuous backup.
- **Regions**: `geo_location` churn re-provisions regions; the
  priority-0 region cannot demote without removing/re-adding. `zone_redundant`
  per region is likewise immutable per region — change via remove/re-add.
- **CMK**: `key_vault_key_id` is the versionless URI form; the identity
  referenced by `default_identity_type`/`identity` needs a Key Vault
  get-policy on the key consumer-side. `default_identity_type` user-assigned
  form is `UserAssignedIdentity=<full ARM ID>` (validated).
- **`location` vs primary region**: keep the account `location` equal to the
  priority-0 `geo_location` region — mismatches are accepted by the API but
  spawn confusing region layouts.
- **`analytical_storage_enabled`** toggling forces replacement — enable
  analytical workloads from the start.
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.DocumentDB/databaseAccounts/write` plus children on scope.

## Import

Accounts import by ARM ID; databases, containers and collections reference
their parents by name:

```
tofu import 'azurerm_cosmosdb_account.account["orders-eu"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<name>"
tofu import 'azurerm_cosmosdb_sql_database.sql_database["orders-eu.orders"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<account-name>/sqlDatabases/<db-name>"
tofu import 'azurerm_cosmosdb_sql_container.sql_container["orders-eu.orders.items"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<account-name>/sqlDatabases/<db-name>/containers/<container-name>"
tofu import 'azurerm_cosmosdb_mongo_database.mongo_database["orders-mongo.catalog"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<account-name>/mongodbDatabases/<db-name>"
tofu import 'azurerm_cosmosdb_mongo_collection.mongo_collection["orders-mongo.catalog.items"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<account-name>/mongodbDatabases/<db-name>/collections/<collection-name>"
```
