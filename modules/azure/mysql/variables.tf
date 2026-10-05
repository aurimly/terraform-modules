variable "mysql_servers" {
  description = "Map of Azure MySQL Flexible Servers keyed by an arbitrary identifier. Each entry creates one azurerm_mysql_flexible_server in the named resource group; server FQDN hosts are unique across all of Azure. Nested databases and firewall rules wire into the server resources this module creates itself."
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
    geo_redundant_backup_enabled      = optional(bool)
    zone                              = optional(string)
    delegated_subnet_id               = optional(string)
    private_dns_zone_id               = optional(string)
    public_network_access             = optional(string, "Enabled")
    storage = optional(object({
      size_gb             = optional(number)
      iops                = optional(number)
      auto_grow_enabled   = optional(bool)
      io_scaling_enabled  = optional(bool)
      log_on_disk_enabled = optional(bool)
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
      charset   = optional(string, "utf8mb4")
      collation = optional(string, "utf8mb4_unicode_ci")
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
      for server in var.mysql_servers : can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", server.name))
    ])
    error_message = "name must be 3–63 characters, lowercase alphanumerics and hyphens only — starting and ending alphanumeric, no leading/trailing hyphen; the server name is the host of its FQDN (<name>.mysql.database.azure.com) and must be unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, server in var.mysql_servers : [
        for other_key, other in var.mysql_servers :
        key == other_key || lower(server.name) != lower(other.name)
      ]
    ]))
    error_message = "server names must be unique across entries, case-insensitively — the FQDN host is case-insensitive, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : length(trimspace(server.name)) > 0 && length(trimspace(server.resource_group_name)) > 0 && length(trimspace(server.location)) > 0 && length(trimspace(server.sku_name)) > 0
    ])
    error_message = "name, resource_group_name, location and sku_name must not be empty — sku_name follows the provider's \"<tier>_<name>\" form (e.g. \"B_Standard_B1ms\", \"GP_Standard_D2ds_v4\", \"MO_Gen5_2\")."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : contains(["Default", "PointInTimeRestore", "GeoRestore", "Replica"], server.create_mode)
    ])
    error_message = "create_mode must be one of Default, PointInTimeRestore, GeoRestore or Replica — create_mode and source_server_id force replacement on change, so keep them intentional."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.create_mode == "Default" || (server.source_server_id != null && can(regex("^/", server.source_server_id)))
    ])
    error_message = "source_server_id is required when create_mode is PointInTimeRestore, GeoRestore or Replica — a full ARM resource ID of the source flexible server (starting with \"/\"). Replicas of a server created in the same invocation are impossible in one input map: split source and replica across two module calls and wire source_server_id from the source's server_id output."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.create_mode != "PointInTimeRestore" || server.point_in_time_restore_time_in_utc != null
    ])
    error_message = "point_in_time_restore_time_in_utc is required when create_mode is PointInTimeRestore — an RFC 3339 timestamp (\"2026-01-02T03:04:05Z\") inside the source's earliest-restore window."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.create_mode != "Default" || (server.administrator_login != null && (server.administrator_password != null) != (server.administrator_password_wo != null) && (server.administrator_password_wo == null || (server.administrator_password_wo_version != null && server.administrator_password_wo_version >= 1)))
    ])
    error_message = "when create_mode is Default, administrator_login is required together with exactly one of administrator_password or administrator_password_wo; administrator_password_wo — the write-only, state-free variant — requires administrator_password_wo_version ≥ 1, and bumping the version rotates the password."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.storage == null || (
        (server.storage.size_gb == null || (server.storage.size_gb >= 20 && server.storage.size_gb <= 16384))
        && (server.storage.iops == null || (server.storage.iops >= 360 && server.storage.iops <= 20000))
        && (server.storage.io_scaling_enabled != true || server.storage.iops == null)
      )
    ])
    error_message = "storage, when set: size_gb must be 20–16384 (scaling down forces replacement), iops 360–20000, and io_scaling_enabled = true is mutually exclusive with iops — io scaling lets the service pick IOPS as size changes."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.high_availability == null || server.storage == null || server.storage.auto_grow_enabled != false
    ])
    error_message = "high_availability requires storage auto-grow enabled — High Availability on MySQL Flexible Server only works with storage auto-grow on; leave auto_grow_enabled unset (default enabled) or set it explicitly to true."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.backup_retention_days == null || (server.backup_retention_days >= 1 && server.backup_retention_days <= 35)
    ])
    error_message = "backup_retention_days must be between 1 and 35."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.high_availability == null || (
        contains(["SameZone", "ZoneRedundant"], server.high_availability.mode)
        && (server.high_availability.mode != "SameZone" || server.high_availability.standby_availability_zone == null)
      )
    ])
    error_message = "high_availability.mode must be SameZone or ZoneRedundant (case-sensitive) — SameZone places the standby in the server's own zone (no standby_availability_zone), ZoneRedundant places it in another zone (optional standby_availability_zone, one of \"1\", \"2\" or \"3\")."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.maintenance_window == null || (
        (server.maintenance_window.day_of_week == null || (server.maintenance_window.day_of_week >= 0 && server.maintenance_window.day_of_week <= 6))
        && (server.maintenance_window.start_hour == null || (server.maintenance_window.start_hour >= 0 && server.maintenance_window.start_hour <= 23))
        && (server.maintenance_window.start_minute == null || (server.maintenance_window.start_minute >= 0 && server.maintenance_window.start_minute <= 59))
      )
    ])
    error_message = "maintenance_window, when set: day_of_week is 0–6 (0 = Sunday), start_hour 0–23 and start_minute 0–59 (server local time)."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.zone == null || contains(["1", "2", "3"], server.zone)
    ])
    error_message = "zone must be \"1\", \"2\" or \"3\" — the availability zone the server and its standby pin to; dropping the zone from an existing server forces replacement (keep it explicit once set)."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.private_dns_zone_id == null || can(regex("\\.mysql\\.database\\.azure\\.com$", server.private_dns_zone_id))
    ])
    error_message = "private_dns_zone_id, when set, must end in \".mysql.database.azure.com\" — the private zone is a sub-zone of the server's FQDN domain; use \"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<zone-name>\" (typically from azure/dns-zone outputs)."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : server.delegated_subnet_id == null || server.private_dns_zone_id != null
    ])
    error_message = "private_dns_zone_id is required when delegated_subnet_id is set — a VNet-integrated server resolves DNS through the private zone; the subnet must carry the Microsoft.DBforMySQL/flexibleServers delegation (see Notes)."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers : contains(["Enabled", "Disabled"], server.public_network_access)
    ])
    error_message = "public_network_access must be \"Enabled\" or \"Disabled\" (case-sensitive) — the provider automatically disables it when a server is created with VNet integration."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.mysql_servers : [
        for rule in server.firewall_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.start_ip_address)) && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.end_ip_address))
      ]
    ]))
    error_message = "firewall_rules start_ip_address and end_ip_address must be bare IPv4 addresses (no CIDR suffix) — Azure takes a range start-to-end; \"0.0.0.0\" for both is the special \"allow all Azure services\" rule (see Notes)."
  }

  validation {
    condition = alltrue([
      for server in var.mysql_servers :
      length(server.tags) <= 50 && alltrue([for tag_key, tag_value in server.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the server."
  }

  validation {
    condition = alltrue(concat(
      [for server_key in keys(var.mysql_servers) : !can(regex("\\.", server_key))],
      flatten([
        for server in var.mysql_servers : [
          for child_key in concat(keys(server.databases), keys(server.firewall_rules)) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of mysql_servers and its nested databases and firewall_rules maps must not contain \".\" — server keys are composed into child identifiers of the form \"<server_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.mysql_servers : [
        length(distinct([for database in server.databases : database.name])) == length(server.databases),
        length(distinct([for rule in server.firewall_rules : lower(rule.name)])) == length(server.firewall_rules)
      ]
    ]))
    error_message = "database names must be unique within their server (case-sensitive — Azure treats database names case-sensitively) and firewall rule names unique within their server, case-insensitively."
  }
}
