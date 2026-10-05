# azure/mysql

Map-keyed module for Azure MySQL Flexible Servers with nested databases and
firewall rules. Each entry creates one `azurerm_mysql_flexible_server` in the
named resource group; server names are unique across all of Azure — they are
the host of the server's FQDN (`<name>.mysql.database.azure.com`). Child
resources wire into the server resources this module creates itself — no
server-name plumbing on the consumer side.

## Destroy semantics (read before using)

- Removing a server key destroys the server and everything on it — databases
  included. There is no soft-delete shadow; keep `prevent_destroy` in mind
  for anything holding data.
- Removing a database or firewall-rule entry deletes it. The provider docs
  recommend `prevent_destroy` on databases (accidental data loss).
- Renaming a server (changing `name`) replaces it and cascades to all of its
  children — the composite `<server_key>.<child_key>` addresses survive, the
  names underneath do not.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `mysql_servers` | `map(object)` | — | Map of MySQL Flexible Servers keyed by an arbitrary unique ID. |

Plan-time validation: `name` is 3–63 characters, lowercase alphanumerics and
hyphens (leading alphanumeric), unique across entries
case-insensitively; `name`/`resource_group_name`/`location`/`sku_name`
non-empty; `create_mode` in the documented set with `source_server_id` and
`point_in_time_restore_time_in_utc` required for the restore/replica modes;
`administrator_login` plus exactly one password variant required when
creating the default way; storage sizing bounds with `io_scaling_enabled`
exclusion and the HA/auto-grow coupling; `backup_retention_days` 1–35;
`high_availability.mode` `SameZone`/`ZoneRedundant` with `SameZone`
forbidding a standby zone; `zone` one of `1`/`2`/`3`; `private_dns_zone_id`
ending in `.mysql.database.azure.com` and required with a delegated subnet;
`public_network_access` `Enabled`/`Disabled`; firewall addresses bare IPv4;
tags respecting the 50/512/256 limits; map keys on every level without `.`;
database names unique per server, firewall rule names unique per server.

### `mysql_servers` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Server name: 3–63 characters, lowercase alphanumerics/hyphens (validated), globally unique (the FQDN host). Immutable — changing it forces replacement and re-creates the children. |
| `resource_group_name` | `string` | — | Resource group the server lives in (typically `dependency.rg.outputs.resource_group_names["platform"]` with the `azure/resource-group` module). Immutable — changing it forces replacement. |
| `location` | `string` | — | Azure region. Immutable — changing it forces replacement. |
| `sku_name` | `string` | — | Server SKU in the provider's `<tier>_<name>` form: `B_Standard_B1ms` (Burstable), `GP_Standard_D2ds_v4` (General Purpose), `MO_Gen5_2` (Memory Optimised) and friends. Immutable — SKU tier changes are provider-side replacements. |
| `version` | `string` | `null` | Engine version: `5.7` or `8.0.21` (and `8.4` on newer providers). Azure retired 5.7 — plan its exit. Immutable — version upgrades force replacement. |
| `create_mode` | `string` | `Default` | `Default` (new server), `PointInTimeRestore` (clone of an existing one inside its retention window), `GeoRestore` (restore from a geo-redundant backup) or `Replica` (read replica). Immutable — changing it forces replacement. Requires `source_server_id` when not `Default` (validated). |
| `source_server_id` | `string` | `null` | Full ARM resource ID of the source server for the non-`Default` modes (validated). Replicas are created in the same resource group and subscription as the source (Azure rule). Passport to a server created in a separate module invocation — see Notes. |
| `administrator_login` | `string` | `null` | Administrator username — required when `create_mode` is `Default` (validated). Only read on creation. |
| `administrator_password` | `string` | `null` | Administrator password — lands in state. Exactly one of this or `administrator_password_wo` (validated). See Notes for the state-exposure stance. |
| `administrator_password_wo` | `string` | `null` | Write-only administrator password — kept out of state (requires a write-only-capable core). Bump `administrator_password_wo_version` to rotate (validated as required with it). |
| `administrator_password_wo_version` | `number` | `null` | Version marker for `administrator_password_wo`, ≥ 1 (validated). |
| `point_in_time_restore_time_in_utc` | `string` | `null` | RFC 3339 timestamp the restore snapshots to — required when `create_mode` is `PointInTimeRestore` (validated). |
| `backup_retention_days` | `number` | `null` | Backup retention in days, 1–35 (provider default 7; validated). |
| `geo_redundant_backup_enabled` | `bool` | `null` | Store backups geo-redundantly — required to later `GeoRestore` in a paired region. Immutable after creation. |
| `zone` | `string` | `null` | Availability zone: `1`, `2` or `3` (validated). Immutable — removing the zone from an existing server forces replacement; keep it explicit once set. |
| `delegated_subnet_id` | `string` | `null` | Full ARM resource ID of a subnet delegated to `Microsoft.DBforMySQL/flexibleServers` for VNet integration. Immutable after creation. Required with `private_dns_zone_id` — see the pair's validation note in Inputs. |
| `private_dns_zone_id` | `string` | `null` | Full ARM resource ID of the private DNS zone backing the server's FQDN, ending in `.mysql.database.azure.com` (validated, required with a delegated subnet). Immutable after creation. |
| `public_network_access` | `string` | `Enabled` | `Enabled` or `Disabled` (case-sensitive, validated) — reachability of the public endpoint. The provider disables it automatically on VNet-integrated servers. |
| `storage` | `object` | `null` | Optional single storage tuning block — see the object table. `null` leaves the provider defaults (size/IOPS per SKU, auto-grow on). |
| `high_availability` | `object` | `null` | Optional single HA block — see the object table. Requires storage auto-grow (validated); enabling HA on a server created without it may force a stop-and-recreate cycle via Azure (provider-side behaviour). |
| `maintenance_window` | `object` | `null` | Optional single maintenance-window block — see the object table. |
| `databases` | `map(object)` | `{}` | Databases on the server keyed by an arbitrary unique ID — see the object table. |
| `firewall_rules` | `map(object)` | `{}` | Firewall rules on the server keyed by an arbitrary unique ID — see the object table. |
| `tags` | `map(string)` | `{}` | Tags on the server. The tag set is authoritative — see Notes. |

### `storage` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `size_gb` | `number` | `null` | Storage size, 20–16384 GB (validated). Scaling down forces replacement; scaling up is in place. |
| `iops` | `number` | `null` | Provisioned IOPS, 360–20000 (validated); unset follows the SKU's built-in allowance. Mutually exclusive with `io_scaling_enabled = true` (validated). |
| `auto_grow_enabled` | `bool` | `null` | Let the service grow storage as it fills up. Provider default `true` — and required by high_availability (validated). |
| `io_scaling_enabled` | `bool` | `null` | Let the service pick IOPS as the size scales (mutually exclusive with `iops`, validated). |
| `log_on_disk_enabled` | `bool` | `null` | Move InnoDB redo logs (and binlogs) onto the data disk. |

### `high_availability` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `mode` | `string` | — | `SameZone` (standby in the server's zone) or `ZoneRedundant` (standby in another zone) — case-sensitive (validated). Changing it triggers a provider-side HA enforce cycle (stop/recreate of the standby side); treat as disruptive. |
| `standby_availability_zone` | `string` | `null` | Standby zone for `ZoneRedundant`: one of `1`, `2`, `3` (leave unset for `SameZone` — validated). |

### `maintenance_window` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `day_of_week` | `number` | `null` | Weekday for maintenance, 0–6 with 0 = Sunday (validated). |
| `start_hour` | `number` | `null` | Start hour in server local time, 0–23 (validated). |
| `start_minute` | `number` | `null` | Start minute, 0–59 (validated). |

### `databases` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Database name — unique within its server (case-sensitive, validated). Immutable — changing it forces replacement. The provider requires `charset` and `collation` explicitly, which the module defaults. |
| `charset` | `string` | `utf8mb4` | Character set (provider-required; module default `utf8mb4`). See the provider/MySQL reference for the full set. |
| `collation` | `string` | `utf8mb4_unicode_ci` | Collation (provider-required; module default `utf8mb4_unicode_ci`). |

### `firewall_rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Rule name — unique within its server (validated). Immutable — changing it forces replacement. |
| `start_ip_address` | `string` | — | Range start as bare IPv4 (validated). `0.0.0.0` paired with `0.0.0.0` is the special "allow all Azure services" rule. |
| `end_ip_address` | `string` | — | Range end as bare IPv4 (validated) — a single address means start = end. |

## Outputs

| Name | Description |
|---|---|
| `server_ids` | Map of server key => full ARM resource ID. |
| `server_names` | Map of server key => server name (what children and the Azure API reference). |
| `server_fqdns` | Map of server key => the server's FQDN — the host connection strings target. |
| `administrator_logins` | Map of server key => administrator login. |
| `replica_capacity` | Map of server key => maximum replica count the SKU supports (0 when none). |
| `database_ids` | Map of `<server_key>.<database_key>` => full ARM resource ID of the database (`<server_id>/databases/<name>`). |
| `firewall_rule_ids` | Map of `<server_key>.<rule_key>` => firewall-rule ARM resource ID. |

No passwords are exposed — the API does not return them and echoing state
would only leak; see Notes.

## Example

```hcl
mysql_servers = {
  "orders-primary" = {
    name                = "mysql-orders-prod-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    sku_name            = "GP_Standard_D2ds_v4"
    version             = "8.0.21"
    administrator_login = "orders_admin"
    administrator_password_wo = var.orders_password
    administrator_password_wo_version = 1
    backup_retention_days           = 14
    geo_redundant_backup_enabled    = true
    zone                            = "1"
    storage = {
      size_gb           = 64
      iops              = 720
      auto_grow_enabled = true
    }
    high_availability = {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
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
  "orders-replica" = {
    name                = "mysql-orders-prod-replica-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    sku_name            = "GP_Standard_D2ds_v4"
    create_mode         = "Replica"
    source_server_id    = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DBforMySQL/flexibleServers/<source-server>"
  }
  "orders-private" = {
    name                = "mysql-orders-vnet-01"
    resource_group_name = "rg-data-prod"
    location            = "westeurope"
    sku_name            = "GP_Standard_D2ds_v4"
    version             = "8.4"
    administrator_login = "orders_admin"
    administrator_password_wo = var.orders_password
    administrator_password_wo_version = 1
    delegated_subnet_id     = dependency.subnet.outputs.subnet_ids["data"]
    private_dns_zone_id     = dependency.dns.outputs.private_dns_zone_ids["mysql"]
    public_network_access   = "Disabled"
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
  accept are not rejected at plan. Replicas are created in the same resource
  group and subscription as the source, always. `GeoRestore` requires the
  source to have `geo_redundant_backup_enabled = true`.
- **Two-invocation replica pattern**: a replica of a server created in the
  same module call cannot be expressed in one input map (inputs cannot
  reference the module's own outputs) — split source and replica across two
  module calls and wire `source_server_id` from the `server_ids` output.
- Azure rejects a claimed FQDN host at apply if it is taken (the module
  cannot check global uniqueness at plan) — rename the map entry and the
  server, then re-plan, when a collision occurs.
- **VNet integration**: the delegated subnet must carry the
  `Microsoft.DBforMySQL/flexibleServers` delegation; `private_dns_zone_id`
  must end in `.mysql.database.azure.com`; the provider sets
  `public_network_access = "Disabled"` automatically when the server is
  created with a delegated subnet (expect that plan diff if set otherwise).
  Pairing with the `azure/dns-zone` module's private-zone output is typical.
- The `0.0.0.0`–`0.0.0.0` firewall rule is the special "allow all Azure
  services" case; anything else is a plain CIDR-free IPv4 range.
- MySQL high availability requires storage auto-grow enabled (validated) —
  enabling HA on a server created without it, or changing `mode`, cycles
  through Azure's HA enforce flow; treat as disruptive.
- `storage.size_gb` scale-down forces replacement; scale-ups are online.
- Engine versions Azure currently accepts: `8.0.21`, `8.4` (`5.7` is
  retired — do not plan new deployments on it). Not enum-validated here —
  Azure retires majors and a pinned list would eventually break valid
  configs; ARM rejects unknown values at apply.
- Tags are authoritative — a change replaces the whole tag set; RBAC needed
  is `Microsoft.DBforMySQL/flexibleServers/write` plus the children
  (`databases`, `firewallRules`) on scope.
- `create_mode` shows a plan diff after import (the API does not return it) —
  expected cosmetic churn for imported servers.
- Not exposed, deliberately (pass-through candidates for a later minor
  release): `identity`, `customer_managed_key`, the
  `azurerm_mysql_flexible_server_active_directory_administrator` Entra
  administrator resource, per-parameter `configuration` resources, and the
  maintenance-window-free `standby_availability_zone`-on-server form Azure
  retired.

## Import

Servers import by ARM ID; databases and firewall rules by theirs:

```
tofu import 'azurerm_mysql_flexible_server.server["orders-primary"]' "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DBforMySQL/flexibleServers/<name>"
tofu import 'azurerm_mysql_flexible_database.database["orders-primary.orders"]' "<server_id>/databases/<database-name>"
tofu import 'azurerm_mysql_flexible_server_firewall_rule.rule["orders-primary.office"]' "<server_id>/firewallRules/<rule-name>"
```
