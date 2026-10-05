# azure/postgresql

Map-keyed module for Azure PostgreSQL Flexible Servers with nested databases
and firewall rules. Each entry creates one `azurerm_postgresql_flexible_server`
in the named resource group; server names are unique across all of Azure — they
are the host of the server's FQDN
(`<name>.postgres.database.azure.com`). Child resources wire into the server
resources this module creates itself — no server-ID plumbing on the consumer
side.

## Destroy semantics (read before using)

- Removing a server key destroys the server and everything on it — databases
  included. There is no soft-delete shadow; keep `prevent_destroy` in mind
  for anything holding data.
- Removing a database or firewall-rule entry deletes it. The provider docs
  recommend `prevent_destroy` on databases (accidental data loss) — add a
  lifecycle block consumer-side if wanted.
- Renaming a server (changing `name`) replaces it and cascades to all of its
  children — the composite `<server_key>.<child_key>` addresses survive, the
  names underneath do not.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `postgresql_servers` | `map(object)` | — | Map of PostgreSQL Flexible Servers keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 3–63 characters, lowercase alphanumerics and
hyphens (leading alphanumeric), unique across entries
case-insensitively; `name`/`resource_group_name`/`location`/`sku_name`
non-empty; `create_mode` in the documented set with `source_server_id`
required for the restore/replica modes and `point_in_time_restore_time_in_utc`
for the restore ones; `version` and `administrator_login` (plus password with
password auth) required when creating the default way; the two storage
architectures (`Premium_LRS` fixed sizes vs `PremiumV2_LRS` flexible
sizes/IOPS/throughput) carry their documented argument rules;
`backup_retention_days` 7–35; `zone` and `high_availability` shapes;
`authentication`'s tenant-ID pairing; a VNet-integrated server requires a
`.postgres.database.azure.com` private DNS zone and public access off;
`administrator_login` present; firewall addresses bare IPv4; tags respecting
the 50/512/256 limits; map keys on every level without `.`; database names
unique per server, firewall rule names unique per server.

### `postgresql_servers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Server name: 3–63 characters, lowercase alphanumerics/hyphens (validated), globally unique (the FQDN host). Immutable — changing it forces replacement and re-creates the children. |
| `resource_group_name` | `string` | — | Resource group the server lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku_name` | `string` | — | Server SKU in the provider's `<tier>_<name>` form: `B_Standard_B1ms` (Burstable), `GP_Standard_D2ds_v4` (General Purpose), `MO_Standard_E2s_v3` (Memory Optimised) and friends. Immutable — SKU tier changes are provider-side replacements. |
| `version` | `string` | `null` | Engine version, currently 11–18 (11/12/13 on Extended Support — see Notes). Required when `create_mode` is `Default` (validated). Immutable — major-version changes force replacement. |
| `create_mode` | `string` | `Default` | `Default` (new server), `PointInTimeRestore` (clone inside a source's retention window), `GeoRestore` (restore from geo-redundant backups), `Replica` (read replica), `ReviveDropped` (recreate a dropped server from backups), `Update` — immutable, forces replacement. Requires `source_server_id` for the first three non-Default restore/replica modes (validated). |
| `source_server_id` | `string` | `null` | Full ARM resource ID of the source server for the restore/replica modes (validated). Passports to a server created in a separate module invocation — see Notes. |
| `administrator_login` | `string` | `null` | Administrator username — required when `create_mode` is `Default` (validated). Immutable after the server exists (cannot be dropped later, only replaced with the server). |
| `administrator_password` | `string` | `null` | Administrator password — lands in state. Required when password auth is on (the default); exactly one of this or `administrator_password_wo` (validated). See Notes. |
| `administrator_password_wo` | `string` | `null` | Write-only administrator password — kept out of state (requires a write-only-capable core). Bump `administrator_password_wo_version` to rotate (validated as required with it). |
| `administrator_password_wo_version` | `number` | `null` | Version marker for `administrator_password_wo`, ≥ 1 (validated). |
| `point_in_time_restore_time_in_utc` | `string` | `null` | RFC 3339 timestamp the restore snapshots to — required when `create_mode` is `PointInTimeRestore` or `GeoRestore` (validated). |
| `backup_retention_days` | `number` | `null` | Backup retention in days, 7–35 (provider default 7; validated). |
| `zone` | `string` | `null` | Availability zone: `1`, `2` or `3` (validated). Immutable — removing the zone from an existing server forces replacement; keep it explicit once set. |
| `storage_mb` | `number` | `null` | Storage size in MB. Under `Premium_LRS` (the default) one of the documented fixed sizes (validated); under `PremiumV2_LRS` any multiple of 1024 in 32768–67108864 (validated). Scale-down forces replacement. |
| `storage_tier` | `string` | `null` | Premium_LRS storage tier (`P4`/`P6`/`P10`…`P80`) — the default follows the provider docs' size-to-tier table; tier changes are rate-limited to one per 12 hours server-side. Not valid with `PremiumV2_LRS` (validated). |
| `storage_iops` | `number` | `null` | Provisioned IOPS, 3000–80000 — required with `PremiumV2_LRS` (validated), unsupported with `Premium_LRS` (validated). |
| `storage_throughput` | `number` | `null` | Provisioned throughput in MB/s, 125–1200 — required with `PremiumV2_LRS` (validated), unsupported with `Premium_LRS` (validated). |
| `storage_type` | `string` | `Premium_LRS` | `Premium_LRS` or `PremiumV2_LRS` (case-sensitive, validated) — the two storage architectures. Immutable — changing it forces replacement. |
| `auto_grow_enabled` | `bool` | `null` | Let the service grow storage as it fills up (Premium_LRS only — validated as unsupported with PremiumV2). Provider default `false` on this engine. |
| `delegated_subnet_id` | `string` | `null` | Full ARM resource ID of a subnet delegated to `Microsoft.DBforPostgreSQL/flexibleServers` for VNet integration. Immutable after creation. Requires `private_dns_zone_id` and closes public access (validated). |
| `private_dns_zone_id` | `string` | `null` | Full ARM resource ID of the private DNS zone backing the server's FQDN, ending in `.postgres.database.azure.com` (validated). Immutable after creation. |
| `public_network_access_enabled` | `bool` | `true` | Public endpoint reachability of the server — set `false` together with VNet integration (validated). |
| `authentication` | `object` | `null` | Optional single auth-features block — see the object table. |
| `high_availability` | `object` | `null` | Optional single HA block — see the object table (same shape as the MySQL module's). |
| `maintenance_window` | `object` | `null` | Optional single maintenance-window block — see the object table. |
| `databases` | `map(object)` | `{}` | Databases on the server keyed by an arbitrary unique ID — see the object table. |
| `firewall_rules` | `map(object)` | `{}` | Firewall rules on the server keyed by an arbitrary unique ID — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the server. The tag set is authoritative — see Notes. |

### `authentication` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `password_auth_enabled` | `bool` | `true` | Keep password logins on. With it off, `administrator_password` becomes unnecessary (validated accordingly when `create_mode` is `Default`) — pair with AD auth so an access path remains (see Notes). |
| `active_directory_auth_enabled` | `bool` | `false` | Allow Entra ID logins — pair with the separate Entra administrator resource (out of this module's scope). |
| `tenant_id` | `string` | `null` | Entra ID tenant UUID the AD logins authenticate against — required with AD auth on, forbidden with it off (validated). |

### `high_availability` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `mode` | `string` | — | `SameZone` (standby in the server's zone) or `ZoneRedundant` (standby in another zone) — case-sensitive (validated). Changing it triggers a provider-side HA swap cycle; treat as disruptive. |
| `standby_availability_zone` | `string` | `null` | Standby zone for `ZoneRedundant`: one of `1`, `2`, `3` (leave unset for `SameZone` — validated). Note: `standby_availability_zone` exists only inside this block — the top-level server argument is `zone` alone. |

### `maintenance_window` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `day_of_week` | `number` | `null` | Weekday for maintenance, 0–6 with 0 = Sunday (validated). |
| `start_hour` | `number` | `null` | Start hour in server local time, 0–23 (validated). |
| `start_minute` | `number` | `null` | Start minute, 0–59 (validated). |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database name — unique within its server (case-sensitive, validated). Immutable — changing it forces replacement. `charset` and `collation` are genuinely optional on this resource (provider defaults supplied in this module). |
| `charset` | `string` | `UTF8` | Character set. |
| `collation` | `string` | `en_US.utf8` | Collation. |

### `firewall_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within its server (validated). Immutable — changing it forces replacement. |
| `start_ip_address` | `string` | — | Range start as bare IPv4 (validated). |
| `end_ip_address` | `string` | — | Range end as bare IPv4 (validated) — a single address means start = end. Note: Flexible Server has no `0.0.0.0`–`0.0.0.0` "allow all Azure services" magic pair (that is the Single Server/MySQL world) — use `public_network_access_enabled` and private access instead. |

## Outputs

| Name | Description |
|---|---|
| `server_ids` | Map of server key => full ARM resource ID. |
| `server_names` | Map of server key => server name. |
| `server_fqdns` | Map of server key => the server's FQDN — the host connection strings target. |
| `administrator_logins` | Map of server key => administrator login. |
| `database_names` | Map of `<server_key>.<database_key>` => database name. |
| `firewall_rule_ids` | Map of `<server_key>.<rule_key>` => firewall-rule ARM resource ID. |

No passwords are exposed — the API does not return them and echoing state
would only leak; see Notes.

## Example

```hcl
postgresql_servers = {
  "orders-primary" = {
    name                = "psql-orders-prod-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    sku_name            = "GP_Standard_D2ds_v4"
    version             = "17"
    administrator_login = "orders_admin"
    administrator_password_wo = var.orders_password
    administrator_password_wo_version = 1
    backup_retention_days     = 14
    zone                      = "1"
    storage_mb                = 65536
    storage_tier              = "P30"
    auto_grow_enabled         = true
    authentication = {
      active_directory_auth_enabled = true
      tenant_id                     = data.azurerm_client_config.current.tenant_id
    }
    maintenance_window = {
      day_of_week  = 3
      start_hour   = 2
      start_minute = 0
    }
    databases = {
      "orders" = {
        name = "orders"
      }
    }
    firewall_rules = {
      "office" = {
        name             = "office"
        start_ip_address = "203.0.113.10"
        end_ip_address   = "203.0.113.30"
      }
    }
    tags = {
      env = "prod"
    }
  }
  "orders-private" = {
    name                = "psql-orders-vnet-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    sku_name            = "GP_Standard_D2ds_v4"
    version             = "17"
    administrator_login = "orders_admin"
    administrator_password_wo = var.orders_password
    administrator_password_wo_version = 1
    storage_type                  = "PremiumV2_LRS"
    storage_mb                    = 131072
    storage_iops                  = 5000
    storage_throughput            = 250
    delegated_subnet_id           = dependency.subnet.outputs.subnet_ids["data"]
    private_dns_zone_id           = dependency.dns.outputs.private_dns_zone_ids["postgres"]
    public_network_access_enabled = false
    high_availability = {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }
  "orders-replica" = {
    name                = "psql-orders-prod-replica-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    sku_name            = "GP_Standard_D2ds_v4"
    create_mode         = "Replica"
    source_server_id    = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/<source-server>"
  }
}
```

## Notes

- **State exposure**: `administrator_password` lands in state; consumers with
  a write-only-capable core use `administrator_password_wo` +
  `administrator_password_wo_version` (bumping the version rotates the
  password) instead. No password output exists — the API does not return
  credentials.
- **Replicas**: Azure rejects administrator credentials when creating a
  replica at the API level (only `administrator_login` carries over) — this
  module documents the rule rather than validating it, so configs ARM might
  accept are not rejected at plan. `GeoRestore` requires the source to be a
  geo-mirrored pair and takes `point_in_time_restore_time_in_utc` too;
  `source_server_id` and `create_mode` force replacement
  on any change.
- **Two-invocation replica pattern**: a replica of a server created in the
  same module call cannot be expressed in one input map (inputs cannot
  reference the module's own outputs) — split source and replica across two
  module calls and wire `source_server_id` from the `server_ids` output.
- Azure rejects a claimed FQDN host at apply if it is taken (the module
  cannot check global uniqueness at plan).
- **VNet integration**: the delegated subnet must carry the
  `Microsoft.DBforPostgreSQL/flexibleServers` delegation; the module
  validates that a VNet posture also turns public access off and pairs the
  `.postgres.database.azure.com` private DNS zone. Pairing with the
  `azure/dns-zone` module's private-zone output is typical.
- **Storage tiers**: `storage_tier` changes are rate-limited to one per 12
  hours server-side; the tier's default depends on `storage_mb` (see the
  provider docs defaults table). Non-`Default` create modes on `Premium_LRS`
  land on the basic tier regardless of the input — set the tier in a
  follow-up update. `PremiumV2_LRS` is the IOPS/throughput-tuned
  architecture: `storage_iops` and `storage_throughput` mandatory,
  `storage_tier`/`auto_grow_enabled` unsupported (all validated).
- **Passwords and auth**: disabling `password_auth_enabled` without AD auth
  enabled leaves the server without a supported login path — plan both
  together; the separate
  `azurerm_postgresql_flexible_server_active_directory_administrator`
  resource (out of this module's scope) creates the AD administrator. The
  `administrator_login` is immutable once the server exists.
- Engine versions: 11–18 accepted today; check the Azure PostgreSQL version
  policy page for 11/12/13 Extended Support status. Not enum-validated here — Azure retires
  majors and a pinned list would eventually break valid configs; ARM rejects
  unknown values at apply.
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.DBforPostgreSQL/flexibleServers/write` plus the children
  (`databases`, `firewallRules`) on scope.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `identity`, `customer_managed_key`, the Entra AD administrator
  resource, the `cluster` block (Postgres 17+, up to 20/32 nodes), per-
  parameter `configuration` resources, and replica-promotion knobs.

## Import

Servers import by ARM ID; databases reference the server by ID and firewall
rules by theirs:

```
tofu import 'azurerm_postgresql_flexible_server.server["orders-primary"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/<name>"
tofu import 'azurerm_postgresql_flexible_server_database.database["orders-primary.orders"]' "<server_id>/databases/<database-name>"
tofu import 'azurerm_postgresql_flexible_server_firewall_rule.rule["orders-primary.office"]' "<server_id>/firewallRules/<rule-name>"
```
