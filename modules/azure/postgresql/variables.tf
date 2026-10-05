variable "postgresql_servers" {
  description = "Map of Azure PostgreSQL Flexible Servers keyed by an arbitrary identifier. Each entry creates one azurerm_postgresql_flexible_server in the named resource group; server FQDN hosts are unique across all of Azure. Nested databases and firewall rules wire into the server resources this module creates itself."
  type = map(object({
    name                              = string
    resource_group_name               = string
    location                          = string
    sku_name                          = string
    version                           = optional(string)
    create_mode                       = optional(string, "Default")
    source_server_id                  = optional(string)
    administrator_login               = optional(string)
    administrator_password            = optional(string)
    administrator_password_wo         = optional(string)
    administrator_password_wo_version = optional(number)
    point_in_time_restore_time_in_utc = optional(string)
    backup_retention_days             = optional(number)
    zone                              = optional(string)
    storage_mb                        = optional(number)
    storage_tier                      = optional(string)
    storage_iops                      = optional(number)
    storage_throughput                = optional(number)
    storage_type                      = optional(string, "Premium_LRS")
    auto_grow_enabled                 = optional(bool)
    delegated_subnet_id               = optional(string)
    private_dns_zone_id               = optional(string)
    public_network_access_enabled     = optional(bool, true)
    authentication = optional(object({
      password_auth_enabled         = optional(bool, true)
      active_directory_auth_enabled = optional(bool, false)
      tenant_id                     = optional(string)
    }))
    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string)
    }))
    maintenance_window = optional(object({
      day_of_week  = optional(number)
      start_hour   = optional(number)
      start_minute = optional(number)
    }))
    databases = optional(map(object({
      name      = string
      charset   = optional(string, "UTF8")
      collation = optional(string, "en_US.utf8")
    })), {})
    firewall_rules = optional(map(object({
      name             = string
      start_ip_address = string
      end_ip_address   = string
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", server.name))
    ])
    error_message = "name must be 3–63 characters, lowercase alphanumerics and hyphens only — starting and ending alphanumeric, no leading/trailing hyphen; the server name is the host of its FQDN (<name>.postgres.database.azure.com) and must be unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, server in var.postgresql_servers : [
        for other_key, other in var.postgresql_servers :
        key == other_key || lower(server.name) != lower(other.name)
      ]
    ]))
    error_message = "server names must be unique across entries, case-insensitively — the FQDN host is case-insensitive, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : length(trimspace(server.name)) > 0 && length(trimspace(server.resource_group_name)) > 0 && length(trimspace(server.location)) > 0 && length(trimspace(server.sku_name)) > 0
    ])
    error_message = "name, resource_group_name, location and sku_name must not be empty — sku_name follows the provider's \"<tier>_<name>\" form (e.g. \"B_Standard_B1ms\", \"GP_Standard_D2ds_v4\")."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : contains(["Default", "GeoRestore", "PointInTimeRestore", "Replica", "ReviveDropped", "Update"], server.create_mode)
    ])
    error_message = "create_mode must be one of Default, GeoRestore, PointInTimeRestore, Replica, ReviveDropped or Update — create_mode and source_server_id force replacement on change, so keep them intentional."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.create_mode == "Default" || contains(["ReviveDropped", "Update"], server.create_mode) || (server.source_server_id != null && can(regex("^/", server.source_server_id)))
    ])
    error_message = "source_server_id is required when create_mode is GeoRestore, PointInTimeRestore or Replica — a full ARM resource ID of the source flexible server (starting with \"/\"). Replicas of a server created in the same invocation are impossible in one input map: split source and replica across two module calls and wire source_server_id from the source's server_id output."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : !contains(["PointInTimeRestore", "GeoRestore"], server.create_mode) || server.point_in_time_restore_time_in_utc != null
    ])
    error_message = "point_in_time_restore_time_in_utc is required when create_mode is PointInTimeRestore or GeoRestore — an RFC 3339 timestamp (\"2026-01-02T03:04:05Z\") inside the source's earliest-restore window."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.create_mode != "Default" || server.version != null
    ])
    error_message = "version is required when create_mode is Default — currently 11 to 18 (11, 12 and 13 on Extended Support); upgrades in the Major Versions forest are provider-side workflows, not input changes."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.create_mode != "Default" || server.administrator_login != null
    ])
    error_message = "administrator_login is required when create_mode is Default — the provider keeps it immutable after creation (removing it later is not possible, only renaming it at the module level forces replacement)."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.create_mode != "Default" || (server.authentication != null && !server.authentication.password_auth_enabled) || ((server.administrator_password != null) != (server.administrator_password_wo != null) && (server.administrator_password_wo == null || (server.administrator_password_wo_version != null && server.administrator_password_wo_version >= 1)))
    ])
    error_message = "when create_mode is Default and password auth is on (the authentication block defaults to it — omitting the block keeps it on), exactly one of administrator_password or administrator_password_wo is required; administrator_password_wo — the write-only, state-free variant — requires administrator_password_wo_version ≥ 1, and bumping the version rotates the password."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.backup_retention_days == null || (server.backup_retention_days >= 7 && server.backup_retention_days <= 35)
    ])
    error_message = "backup_retention_days must be between 7 and 35."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.zone == null || contains(["1", "2", "3"], server.zone)
    ])
    error_message = "zone must be \"1\", \"2\" or \"3\" — the availability zone the server pins to; dropping the zone from an existing server forces replacement (keep it explicit once set)."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.storage_type == "Premium_LRS" || server.storage_type == "PremiumV2_LRS"
    ])
    error_message = "storage_type must be \"Premium_LRS\" or \"PremiumV2_LRS\" (default Premium_LRS) — the two storage architectures, with different supported arguments (see the following storage validations)."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.storage_type == "PremiumV2_LRS" || server.storage_mb == null || contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 4195328, 8387584, 16775168, 33553408], server.storage_mb)
    ])
    error_message = "storage_mb under Premium_LRS must be one of the documented sizes (32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 4195328, 8387584, 16775168, 33553408) — scaling down forces replacement."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.storage_type != "PremiumV2_LRS" || server.storage_mb == null || (server.storage_mb % 1024 == 0 && server.storage_mb >= 32768 && server.storage_mb <= 67108864)
    ])
    error_message = "storage_mb under PremiumV2_LRS must be a multiple of 1024 between 32768 and 67108864 — the flexible storage architecture; scaling down forces replacement."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.storage_type == "PremiumV2_LRS" || (server.storage_iops == null && server.storage_throughput == null)
    ])
    error_message = "Premium_LRS takes no storage_iops or storage_throughput — IOPS and throughput follow the size; those arguments belong to PremiumV2_LRS only."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.storage_type != "PremiumV2_LRS" || (server.storage_iops != null && server.storage_throughput != null && server.storage_iops >= 3000 && server.storage_iops <= 80000 && server.storage_throughput >= 125 && server.storage_throughput <= 1200)
    ])
    error_message = "PremiumV2_LRS requires storage_iops (3000–80000) and storage_throughput (125–1200 MB/s) — both arguments are mandatory on the flexible storage architecture."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.storage_type != "PremiumV2_LRS" || (server.storage_tier == null && server.auto_grow_enabled == null)
    ])
    error_message = "PremiumV2_LRS takes no storage_tier or auto_grow_enabled — storage tiering and auto-grow belong to Premium_LRS."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.authentication == null || ((server.authentication.active_directory_auth_enabled && server.authentication.tenant_id != null) || (!server.authentication.active_directory_auth_enabled && server.authentication.tenant_id == null))
    ])
    error_message = "authentication.tenant_id is required when active_directory_auth_enabled is true and must stay unset when it is false — the Entra ID tenant the AD logins authenticate against (typically data.azurerm_client_config.current.tenant_id)."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.high_availability == null || (
        contains(["SameZone", "ZoneRedundant"], server.high_availability.mode)
        && (server.high_availability.mode != "SameZone" || server.high_availability.standby_availability_zone == null)
      )
    ])
    error_message = "high_availability.mode must be SameZone or ZoneRedundant (case-sensitive) — SameZone places the standby in the server's own zone (no standby_availability_zone), ZoneRedundant places it in another zone (optional standby_availability_zone, one of \"1\", \"2\" or \"3\")."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.maintenance_window == null || (
        (server.maintenance_window.day_of_week == null || (server.maintenance_window.day_of_week >= 0 && server.maintenance_window.day_of_week <= 6))
        && (server.maintenance_window.start_hour == null || (server.maintenance_window.start_hour >= 0 && server.maintenance_window.start_hour <= 23))
        && (server.maintenance_window.start_minute == null || (server.maintenance_window.start_minute >= 0 && server.maintenance_window.start_minute <= 59))
      )
    ])
    error_message = "maintenance_window, when set: day_of_week is 0–6 (0 = Sunday), start_hour 0–23 and start_minute 0–59 (server local time)."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.delegated_subnet_id == null || (server.private_dns_zone_id != null && server.public_network_access_enabled == false)
    ])
    error_message = "a VNet-integrated server (delegated_subnet_id set) requires private_dns_zone_id and public_network_access_enabled = false — the subnet must carry the Microsoft.DBforPostgreSQL/flexibleServers delegation and the public endpoint is closed in that posture."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers : server.private_dns_zone_id == null || can(regex("\\.postgres\\.database\\.azure\\.com$", server.private_dns_zone_id))
    ])
    error_message = "private_dns_zone_id, when set, must end in \".postgres.database.azure.com\" — the private zone is a sub-zone of the server's FQDN domain; use \"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<zone-name>\" (typically from azure/dns-zone outputs)."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.postgresql_servers : [
        for rule in server.firewall_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.start_ip_address)) && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.end_ip_address))
      ]
    ]))
    error_message = "firewall_rules start_ip_address and end_ip_address must be bare IPv4 addresses (no CIDR suffix) — Azure takes a range start-to-end; PostgreSQL Flexible Server has no \"allow all Azure services\" magic pair (see Notes)."
  }

  validation {
    condition = alltrue([
      for server in var.postgresql_servers :
      length(server.tags) <= 50 && alltrue([for tag_key, tag_value in server.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the server."
  }

  validation {
    condition = alltrue(concat(
      [for server_key in keys(var.postgresql_servers) : !can(regex("\\.", server_key))],
      flatten([
        for server in var.postgresql_servers : [
          for child_key in concat(keys(server.databases), keys(server.firewall_rules)) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of postgresql_servers and its nested databases and firewall_rules maps must not contain \".\" — server keys are composed into child identifiers of the form \"<server_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.postgresql_servers : [
        length(distinct([for database in server.databases : database.name])) == length(server.databases),
        length(distinct([for rule in server.firewall_rules : lower(rule.name)])) == length(server.firewall_rules)
      ]
    ]))
    error_message = "database names must be unique within their server (case-sensitive — PostgreSQL treats database names case-sensitively) and firewall rule names unique within their server, case-insensitively."
  }
}
