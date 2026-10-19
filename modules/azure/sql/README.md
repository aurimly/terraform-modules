# azure/sql

Map-keyed module for Azure SQL Database (`azurerm_mssql_*` — not Managed
Instance). Each entry creates one `azurerm_mssql_server` in the named
resource group; server names are unique across all of Azure — they are the
host of the server's FQDN (`<name>.database.windows.net`). Nested
databases, firewall rules, elastic pools and failover groups wire into the
server resources this module creates itself — no server-name plumbing on
the consumer side.

## Destroy semantics (read before using)

- Removing a server key destroys the server and everything on it —
  databases included. There is no soft-delete shadow; the provider docs
  recommend `prevent_destroy` on databases against accidental data loss —
  keep that in mind for anything holding data.
- Removing a database, elastic pool, firewall rule or failover group entry
  deletes it.
- Renaming a server (changing `name`) replaces it and cascades to all of
  its children — the composite `<server_key>.<child_key>` addresses
  survive, the names underneath do not.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `sql_servers` | `map(object)` | — | Map of SQL logical servers keyed by an arbitrary unique ID. |

Plan-time validation: `name` lowercase alphanumerics/hyphens, up to 63
characters, unique across entries case-insensitively; `name`/
`resource_group_name`/`location` non-empty; `version` pinned to `12.0`;
`administrator_login` plus exactly one password variant required unless
Entra-only authentication; identity/CMK couplings (`identity_ids`,
`primary_user_assigned_identity_id`, key-vault key shape);
`connection_policy` in the documented set; elastic pool SKU/sizing with
exactly one of `max_size_gb`/`max_size_bytes` and per-database
min ≤ max; database `create_mode` requiring its matching source argument,
`max_size_gb` bounds and `Secondary`/`OnlineSecondary` exclusion;
`elastic_pool_key` resolving to a sibling pool and forcing
`sku_name = "ElasticPool"`; retention policy bounds; failover group
partner/grace/database-keys couplings; firewall addresses bare IPv4;
names unique within each family per server; tags respecting the 50/512/256
limits; map keys on every level without `.`.

### `sql_servers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Server name: lowercase alphanumerics and hyphens, up to 63 characters (validated), globally unique — the FQDN host. Immutable — changing it forces replacement and re-creates the children. |
| `resource_group_name` | `string` | — | Resource group the server lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `version` | `string` | `12.0` | Server platform version — pinned to `12.0` (validated). |
| `administrator_login` | `string` | `null` | Administrator username — required with a password variant unless `azuread_administrator.azuread_authentication_only = true` (validated). Azure generates a login when omitted; read it back from the `administrator_logins` output. |
| `administrator_login_password` | `string` | `null` | Administrator password — lands in state. Exactly one of this or `administrator_login_password_wo` (validated). See Notes for the state-exposure stance. |
| `administrator_login_password_wo` | `string` | `null` | Write-only administrator password — kept out of state (requires a write-only-capable core). Bump `administrator_login_password_wo_version` to rotate (validated as required with it). |
| `administrator_login_password_wo_version` | `number` | `null` | Version marker for `administrator_login_password_wo`, ≥ 1 (validated). |
| `azuread_administrator` | `object` | `null` | Optional single Entra administrator block — see the object table. |
| `identity` | `object` | `null` | Optional single managed-identity block — see the object table. Required for CMK TDE (validated). |
| `primary_user_assigned_identity_id` | `string` | `null` | Full ARM resource ID of the primary user-assigned identity — required when `identity.type` includes `UserAssigned` (validated), and what TDE/auditing run as. |
| `transparent_data_encryption_key_vault_key_id` | `string` | `null` | Fully versioned Key Vault key URL for customer-managed TDE — requires identity wiring (validated); see Notes for the vault requirements. |
| `minimum_tls_version` | `string` | `1.2` | Minimum TLS for connections — `1.2` is the only version Azure still accepts; the module sets it explicitly. |
| `connection_policy` | `string` | `Default` | `Default`, `Proxy` or `Redirect` (case-sensitive, validated) — SQL gateway connection policy. |
| `public_network_access_enabled` | `bool` | `true` | Reachability of the public endpoint. |
| `outbound_network_restriction_enabled` | `bool` | `false` | Restrict outbound connections from the server to virtual network rules. |
| `express_vulnerability_assessment_enabled` | `bool` | `false` | Express vulnerability assessment on the server. |
| `elastic_pools` | `map(object)` | `{}` | Elastic pools on the server keyed by an arbitrary unique ID — see the object table. |
| `databases` | `map(object)` | `{}` | Databases on the server keyed by an arbitrary unique ID — see the object table. |
| `firewall_rules` | `map(object)` | `{}` | Firewall rules on the server keyed by an arbitrary unique ID — see the object table. |
| `failover_groups` | `map(object)` | `{}` | Failover groups anchored on this server keyed by an arbitrary unique ID — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the server. The tag set is authoritative — see Notes. |

### `azuread_administrator` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `login_username` | `string` | — | Entra group or user name the admin maps to. |
| `object_id` | `string` | — | Entra object ID of the admin (group/user/service principal). |
| `tenant_id` | `string` | `null` | Tenant of the admin — defaults to the provider tenant. Expect a plan diff on imported servers if left unset (the API fills it back). |
| `azuread_authentication_only` | `bool` | `null` | Disable SQL authentication entirely — the one path that legitimately omits `administrator_login` and passwords (validated). |

### `identity` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | — | `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned`. |
| `identity_ids` | `list(string)` | `null` | Full ARM resource IDs of the user-assigned identities — required for the `UserAssigned` types (validated). |

### `elastic_pools` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Pool name — unique within its server (validated). Immutable — changing it forces replacement. |
| `sku` | `object` | — | Single SKU block: `name` (`GP_Gen5`, `BC_Gen5`, `HS_Gen5`, `StandardPool`, `PremiumPool`, ...), `tier` (`GeneralPurpose`, `BusinessCritical`, `Hyperscale`, `Basic`, `Standard`, `Premium`), `capacity` (vCores or eDTUs), `family` (e.g. `Gen5`). Non-empty, capacity ≥ 1 (validated). |
| `max_size_gb` | `number` | `null` | Pool max size in GB — exactly one of this or `max_size_bytes` (validated). |
| `max_size_bytes` | `number` | `null` | Pool max size in bytes — exactly one of the two (validated). |
| `per_database_settings` | `object` | — | Single block: `min_capacity` and `max_capacity` bounding each database's slice of the pool — min ≤ max (validated). |
| `license_type` | `string` | `null` | `LicenseIncluded` or `BasePrice` (Azure Hybrid Benefit). |
| `zone_redundant` | `bool` | `null` | Zone-redundant pool — Premium/BusinessCritical only server-side. |
| `high_availability_replica_count` | `number` | `null` | Extra Hyperscale replicas, 0–4 (validated). |
| `maintenance_configuration_name` | `string` | `null` | Maintenance window, e.g. `SQL_WestEurope_DB_1`. |
| `enclave_type` | `string` | `null` | `Default` or `VBS` — Always Encrypted enclaves. |
| `tags` | `map(string)` | `{}` | Tags on the pool. |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database name — unique within its server (validated). Immutable — changing it forces replacement. |
| `collation` | `string` | `null` | Collation — the server default (`SQL_Latin1_General_CP1_CI_AS`) when unset. Immutable. |
| `sku_name` | `string` | `null` | SKU: `GP_Gen5_2`, `BC_Gen5_2`, `HS_Gen5_2`, `S0`, `P2`, `ElasticPool`, ... When joining a pool (`elastic_pool_key`), must be `ElasticPool` (validated). |
| `license_type` | `string` | `null` | `LicenseIncluded` or `BasePrice` (Azure Hybrid Benefit). |
| `max_size_gb` | `number` | `null` | Max size in GB — `0.1`/`0.5`/integer ≥ 1; cannot be set on `Secondary`/`OnlineSecondary` (they inherit the source's size; validated). |
| `create_mode` | `string` | `Default` | `Default` (new), `Copy`, `OnlineSecondary`, `PointInTimeRestore`, `Recovery`, `Restore`, `RestoreExternalBackup`, `RestoreExternalBackupSecondary`, `RestoreLongTermRetentionBackup` or `Secondary` — Copy/OnlineSecondary/Secondary/PointInTimeRestore/Recovery/Restore and the LTR restore require their matching source argument (validated); the external-backup restores carry no module-visible source argument. Immutable — changing it forces replacement. |
| `creation_source_database_id` | `string` | `null` | Full ARM resource ID of the source database — required for `Copy`/`OnlineSecondary`/`Secondary`/`PointInTimeRestore` (validated). Pass one from a separate module invocation — see Notes. |
| `restore_point_in_time` | `string` | `null` | RFC 3339 timestamp for `PointInTimeRestore` (validated). |
| `recover_database_id` | `string` | `null` | Source database ARM ID for `Recovery` (validated). |
| `recovery_point_id` | `string` | `null` | Recovery Services recovery point ID for `Recovery`. |
| `restore_dropped_database_id` | `string` | `null` | Dropped-database ARM ID for `Restore` (validated). |
| `restore_long_term_retention_backup_id` | `string` | `null` | LTR backup ARM ID for `RestoreLongTermRetentionBackup` (validated). |
| `elastic_pool_key` | `string` | `null` | Sibling `elastic_pools` key to join (validated) — sets `sku_name = "ElasticPool"`. |
| `zone_redundant` | `bool` | `null` | Zone redundancy — Premium/BusinessCritical only server-side. |
| `read_scale` | `bool` | `null` | Route application-intent=readonly connections to a replica — Premium/BusinessCritical. |
| `read_replica_count` | `number` | `null` | Hyperscale readonly replicas. |
| `storage_account_type` | `string` | `Geo` | Backup storage: `Geo`, `GeoZone`, `Local` or `Zone` (case-sensitive, validated). Immutable. |
| `min_capacity` | `number` | `null` | Serverless floor. |
| `auto_pause_delay_in_minutes` | `number` | `null` | Serverless auto-pause delay; `-1` disables pausing. |
| `ledger_enabled` | `bool` | `null` | Ledger database. Immutable. |
| `enclave_type` | `string` | `null` | `Default` or `VBS` — Always Encrypted enclaves. |
| `geo_backup_enabled` | `bool` | `null` | Geo-backup policy — defaults `true`; disabling only applies to Data Warehouse SKUs (see Notes). |
| `maintenance_configuration_name` | `string` | `null` | Maintenance window, e.g. `SQL_WestEurope_DB_1`. |
| `transparent_data_encryption_enabled` | `bool` | `null` | TDE on the database — disabling only applies to Data Warehouse SKUs (see Notes). |
| `short_term_retention_policy` | `object` | `null` | PITR backup retention — see the object table. |
| `long_term_retention_policy` | `object` | `null` | LTR backup retention — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the database. |

### `databases.short_term_retention_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `retention_days` | `number` | — | PITR retention, 1–35 days (validated). |
| `backup_interval_in_hours` | `number` | `null` | Differential backup interval, 12 or 24 (validated). |

### `databases.long_term_retention_policy` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `weekly_retention` | `string` | `null` | ISO-8601 duration, e.g. `P1W`, `P7D` (validated shape). |
| `monthly_retention` | `string` | `null` | ISO-8601 duration, e.g. `P1M` (validated shape). |
| `yearly_retention` | `string` | `null` | ISO-8601 duration, e.g. `P1Y` (validated shape). |
| `week_of_year` | `number` | `null` | Week the yearly backup lands in, 1–52 (validated). |

### `firewall_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within its server (validated). Immutable — changing it forces replacement. |
| `start_ip_address` | `string` | — | Range start as bare IPv4 (validated). `0.0.0.0` paired with `0.0.0.0` is the special "allow all Azure services" rule. |
| `end_ip_address` | `string` | — | Range end as bare IPv4 (validated) — a single address means start = end. |

### `failover_groups` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Failover group name — unique within its server (validated); the group's DNS record is `<name>.<server-name>.database.windows.net`. Immutable. |
| `partner_server_id` | `string` | — | Full ARM resource ID of the partner (secondary) server — pass one from a second module invocation's `server_ids` output (validated; see Notes). |
| `database_keys` | `list(string)` | `[]` | Sibling `databases` keys to add to the group (validated) — the module resolves them to database ARM IDs. |
| `read_write_endpoint_failover_policy` | `object` | — | Single block: `mode` (`Automatic` or `Manual`, case-sensitive, validated) and `grace_minutes` (≥ 1, required for `Automatic` — validated). |
| `readonly_endpoint_failover_policy_enabled` | `bool` | `false` | Expose the read-only listener endpoint. |
| `tags` | `map(string)` | `{}` | Tags on the failover group. |

## Outputs

| Name | Description |
|---|---|
| `server_ids` | Map of server key => full ARM resource ID. |
| `server_names` | Map of server key => server name (what children and the Azure API reference). |
| `server_fqdns` | Map of server key => the server's FQDN — the host connection strings target. |
| `administrator_logins` | Map of server key => administrator login (Azure-generated when omitted). |
| `server_identity_principal_ids` | Map of server key => principal ID of the system-assigned identity (null without one) — grant this Key Vault permissions in CMK setups. |
| `database_ids` | Map of `<server_key>.<database_key>` => full ARM resource ID of the database (`<server_id>/databases/<name>`). |
| `firewall_rule_ids` | Map of `<server_key>.<rule_key>` => firewall-rule ARM resource ID. |
| `elastic_pool_ids` | Map of `<server_key>.<pool_key>` => elastic pool ARM resource ID. |
| `failover_group_ids` | Map of `<server_key>.<group_key>` => failover group ARM resource ID. |

No passwords are exposed — the API does not return them and echoing state
would only leak; see Notes.

## Example

```hcl
sql_servers = {
  "orders-primary" = {
    name                = "sql-orders-prod-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    administrator_login = "orders_admin"
    administrator_login_password_wo         = var.orders_password
    administrator_login_password_wo_version = 1
    azuread_administrator = {
      login_username              = "sql-admins"
      object_id                   = "11111111-2222-3333-4444-555555555555"
      azuread_authentication_only = false
    }

    elastic_pools = {
      "main" = {
        name = "pool-orders-prod"
        sku = {
          name     = "GP_Gen5"
          tier     = "GeneralPurpose"
          capacity = 4
          family   = "Gen5"
        }
        max_size_gb = 1024
        per_database_settings = {
          min_capacity = 0.5
          max_capacity = 4
        }
      }
    }

    databases = {
      "orders" = {
        name       = "orders"
        collation  = "SQL_Latin1_General_CP1_CI_AS"
        sku_name   = "GP_Gen5_2"
        max_size_gb = 128
        storage_account_type = "GeoZone"
        short_term_retention_policy = {
          retention_days           = 21
          backup_interval_in_hours = 12
        }
        long_term_retention_policy = {
          weekly_retention  = "P1W"
          monthly_retention = "P1M"
          yearly_retention  = "P1Y"
          week_of_year      = 1
        }
      }
      "pooled" = {
        name            = "orders-pooled"
        sku_name        = "ElasticPool"
        elastic_pool_key = "main"
      }
    }

    firewall_rules = {
      "office" = {
        name             = "office"
        start_ip_address = "203.0.113.10"
        end_ip_address   = "203.0.113.30"
      }
    }

    failover_groups = {
      "main" = {
        name              = "fog-orders-prod"
        partner_server_id = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Sql/servers/<partner-server>"
        database_keys     = ["orders"]
        read_write_endpoint_failover_policy = {
          mode          = "Automatic"
          grace_minutes = 60
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

- **State exposure**: `administrator_login_password` lands in state;
  consumers with a write-only-capable core use
  `administrator_login_password_wo` +
  `administrator_login_password_wo_version` (bumping the version rotates
  the password) instead. No password output exists — the API does not
  return credentials.
- **Two-invocation pattern for copies and failover groups**: a database
  copy/secondary of a database created in the same module call, and a
  failover group whose partner is a server from the same call, cannot be
  expressed in one input map (inputs cannot reference the module's own
  outputs) — split the source and target across two module calls and wire
  `creation_source_database_id` / `partner_server_id` from the
  `server_ids` / `database_ids` outputs. `failover_groups` database_keys
  only reach siblings of the same server entry.
- **CMK/BYOK TDE**: the Key Vault must have soft-delete and purge
  protection enabled, live in the same tenant as the server, and grant the
  server's primary identity get/wrap/unwrap key permissions. The key ID is
  the fully versioned URL (`https://<vault>.vault.azure.net/keys/<key>/<version>`).
- The `0.0.0.0`–`0.0.0.0` firewall rule is the special "allow all Azure
  services" case; anything else is a plain CIDR-free IPv4 range.
- `transparent_data_encryption_enabled = false` and
  `geo_backup_enabled = false` only apply to Data Warehouse SKUs — on
  other SKUs the API rejects or silently ignores them.
- Server names collide at apply when taken (the module cannot check global
  uniqueness at plan) — rename the map entry and the server, then
  re-plan.
- Entra administrator blocks diff after import (the API fills back
  `tenant_id`) — expected cosmetic churn.
- Tags are authoritative — a change replaces the whole tag set; RBAC
  needed is `Microsoft.Sql/servers/write` plus the children (`databases`,
  `elasticPools`, `firewallRules`, `failoverGroups`) on scope.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): database-level `identity` and CMK TDE (server-level carries
  the common case), the `import` (BACPAC) block and
  `threat_detection_policy` (legacy shape), the extended auditing /
  security-alert satellites, server DNS aliases, outbound firewall rules,
  and Managed Instance (its own resource family).

## Import

Servers import by ARM ID; children by theirs:

```
tofu import 'azurerm_mssql_server.server["orders-primary"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Sql/servers/<name>"
tofu import 'azurerm_mssql_database.database["orders-primary.orders"]' "<server_id>/databases/<database-name>"
tofu import 'azurerm_mssql_firewall_rule.rule["orders-primary.office"]' "<server_id>/firewallRules/<rule-name>"
tofu import 'azurerm_mssql_elasticpool.pool["orders-primary.main"]' "<server_id>/elasticPools/<pool-name>"
tofu import 'azurerm_mssql_failover_group.failover_group["orders-primary.main"]' "<server_id>/failoverGroups/<group-name>"
```
