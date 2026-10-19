variable "sql_servers" {
  description = "Map of Azure SQL logical servers keyed by an arbitrary identifier. Each entry creates one azurerm_mssql_server in the named resource group; server names are globally unique across all of Azure — the host of the <name>.database.windows.net FQDN. Nested databases, firewall rules, elastic pools and failover groups wire into the server resources this module creates itself."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    version             = optional(string, "12.0")

    administrator_login                     = optional(string)
    administrator_login_password            = optional(string)
    administrator_login_password_wo         = optional(string)
    administrator_login_password_wo_version = optional(number)

    azuread_administrator = optional(object({
      login_username              = string
      object_id                   = string
      tenant_id                   = optional(string)
      azuread_authentication_only = optional(bool)
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    primary_user_assigned_identity_id            = optional(string)
    transparent_data_encryption_key_vault_key_id = optional(string)

    minimum_tls_version                      = optional(string, "1.2")
    connection_policy                        = optional(string, "Default")
    public_network_access_enabled            = optional(bool, true)
    outbound_network_restriction_enabled     = optional(bool, false)
    express_vulnerability_assessment_enabled = optional(bool, false)

    elastic_pools = optional(map(object({
      name = string
      sku = object({
        name     = string
        tier     = string
        capacity = number
        family   = optional(string)
      })
      max_size_gb    = optional(number)
      max_size_bytes = optional(number)
      per_database_settings = object({
        min_capacity = number
        max_capacity = number
      })
      license_type                    = optional(string)
      zone_redundant                  = optional(bool)
      high_availability_replica_count = optional(number)
      maintenance_configuration_name  = optional(string)
      enclave_type                    = optional(string)
      tags                            = optional(map(string), {})
    })), {})

    databases = optional(map(object({
      name                                  = string
      collation                             = optional(string)
      sku_name                              = optional(string)
      license_type                          = optional(string)
      max_size_gb                           = optional(number)
      create_mode                           = optional(string, "Default")
      creation_source_database_id           = optional(string)
      restore_point_in_time                 = optional(string)
      recover_database_id                   = optional(string)
      recovery_point_id                     = optional(string)
      restore_dropped_database_id           = optional(string)
      restore_long_term_retention_backup_id = optional(string)
      elastic_pool_key                      = optional(string)
      zone_redundant                        = optional(bool)
      read_scale                            = optional(bool)
      read_replica_count                    = optional(number)
      storage_account_type                  = optional(string, "Geo")
      min_capacity                          = optional(number)
      auto_pause_delay_in_minutes           = optional(number)
      ledger_enabled                        = optional(bool)
      enclave_type                          = optional(string)
      geo_backup_enabled                    = optional(bool)
      maintenance_configuration_name        = optional(string)
      transparent_data_encryption_enabled   = optional(bool)
      short_term_retention_policy = optional(object({
        retention_days           = number
        backup_interval_in_hours = optional(number)
      }))
      long_term_retention_policy = optional(object({
        weekly_retention  = optional(string)
        monthly_retention = optional(string)
        yearly_retention  = optional(string)
        week_of_year      = optional(number)
      }))
      tags = optional(map(string), {})
    })), {})

    firewall_rules = optional(map(object({
      name             = string
      start_ip_address = string
      end_ip_address   = string
    })), {})

    failover_groups = optional(map(object({
      name              = string
      partner_server_id = string
      database_keys     = optional(list(string), [])
      read_write_endpoint_failover_policy = object({
        mode          = string
        grace_minutes = optional(number)
      })
      readonly_endpoint_failover_policy_enabled = optional(bool, false)
      tags                                      = optional(map(string), {})
    })), {})

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for server in var.sql_servers : can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", server.name))
    ])
    error_message = "name must be lowercase alphanumerics and hyphens only — starting and ending alphanumeric, up to 63 characters; the server name is the host of its FQDN (<name>.database.windows.net) and must be unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for key, server in var.sql_servers : [
        for other_key, other in var.sql_servers :
        key == other_key || lower(server.name) != lower(other.name)
      ]
    ]))
    error_message = "server names must be unique across entries, case-insensitively — the FQDN host is case-insensitive, so two entries with the same name collide at the Azure API."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : length(trimspace(server.name)) > 0 && length(trimspace(server.resource_group_name)) > 0 && length(trimspace(server.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.version == "12.0"
    ])
    error_message = "version must be \"12.0\" — the Azure SQL Database v12 platform (the provider accepts \"2.0\" for the retired v11 platform, which new deployments must not use; the module pins it out)."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.azuread_administrator != null && server.azuread_administrator.azuread_authentication_only == true ? true : (
        server.administrator_login != null
        && (server.administrator_login_password != null) != (server.administrator_login_password_wo != null)
        && (server.administrator_login_password_wo == null || (server.administrator_login_password_wo_version != null && server.administrator_login_password_wo_version >= 1))
      )
    ])
    error_message = "administrator_login is required together with exactly one of administrator_login_password or administrator_login_password_wo, unless azuread_administrator.azuread_authentication_only = true (Entra-only authentication, no SQL credentials); administrator_login_password_wo — the write-only, state-free variant — requires administrator_login_password_wo_version ≥ 1, and bumping the version rotates the password."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.identity == null || server.identity.type == "SystemAssigned" || server.identity.identity_ids != null
    ])
    error_message = "identity.identity_ids is required when identity.type is UserAssigned or \"SystemAssigned, UserAssigned\" — a list of full ARM resource IDs of the user-assigned managed identities (typically from the azure/managed-identity module)."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.identity == null || server.identity.type == "SystemAssigned" || server.primary_user_assigned_identity_id != null
    ])
    error_message = "primary_user_assigned_identity_id is required when identity.type is UserAssigned or \"SystemAssigned, UserAssigned\" — the server's primary identity is what TDE and auditing run as; the provider sets it from identity_ids implicitly but requires it explicitly."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.primary_user_assigned_identity_id == null || server.identity == null || contains(coalesce(server.identity.identity_ids, []), server.primary_user_assigned_identity_id)
    ])
    error_message = "primary_user_assigned_identity_id must appear in identity.identity_ids — the primary identity is one of the identities assigned to the server."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.transparent_data_encryption_key_vault_key_id == null || (server.identity != null && server.primary_user_assigned_identity_id != null)
    ])
    error_message = "transparent_data_encryption_key_vault_key_id (customer-managed TDE) requires identity and primary_user_assigned_identity_id — the key vault must grant the server's primary identity get/unwraps key permissions, be in the same tenant, and have soft-delete and purge protection enabled (see Notes)."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : server.transparent_data_encryption_key_vault_key_id == null || can(regex("^/", server.transparent_data_encryption_key_vault_key_id))
    ])
    error_message = "transparent_data_encryption_key_vault_key_id, when set, must be a full ARM resource ID of the Key Vault key (starting with \"/\", e.g. \"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>/keys/<key>\")."
  }

  validation {
    condition = alltrue([
      for server in var.sql_servers : contains(["Default", "Proxy", "Redirect"], server.connection_policy)
    ])
    error_message = "connection_policy must be Default, Proxy or Redirect (case-sensitive) — Redirect requires client-side reachability to the data nodes and is only meaningful for clients inside Azure."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        for pool_key, pool in server.elastic_pools : [
          length(trimspace(pool.name)) > 0 && length(trimspace(pool.sku.name)) > 0 && length(trimspace(pool.sku.tier)) > 0 && pool.sku.capacity >= 1,
          (pool.max_size_gb != null) != (pool.max_size_bytes != null),
          pool.per_database_settings.min_capacity <= pool.per_database_settings.max_capacity,
          pool.high_availability_replica_count == null || (pool.high_availability_replica_count >= 0 && pool.high_availability_replica_count <= 4)
        ]
      ]
    ]))
    error_message = "elastic_pools: name, sku.name and sku.tier must not be empty and sku.capacity at least 1; exactly one of max_size_gb or max_size_bytes; per_database_settings min_capacity must not exceed max_capacity; high_availability_replica_count (Hyperscale) 0–4 when set. Pool names must be unique within their server, case-insensitively."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        for db_key, db in server.databases : [
          contains(["Default", "Copy", "OnlineSecondary", "PointInTimeRestore", "Recovery", "Restore", "RestoreExternalBackup", "RestoreExternalBackupSecondary", "RestoreLongTermRetentionBackup", "Secondary"], db.create_mode),
          db.create_mode == "Default" || (contains(["Copy", "OnlineSecondary", "Secondary", "PointInTimeRestore"], db.create_mode) ? db.creation_source_database_id != null : db.create_mode == "Recovery" ? db.recover_database_id != null : db.create_mode == "Restore" ? db.restore_dropped_database_id != null : db.create_mode == "RestoreLongTermRetentionBackup" ? db.restore_long_term_retention_backup_id != null : true),
          db.create_mode != "PointInTimeRestore" || db.restore_point_in_time != null,
          db.max_size_gb == null || db.max_size_gb >= 0.1,
          !contains(["Secondary", "OnlineSecondary"], db.create_mode) || db.max_size_gb == null,
          contains(["Geo", "GeoZone", "Local", "Zone"], db.storage_account_type)
        ]
      ]
    ]))
    error_message = "databases: create_mode must be one of Default, Copy, OnlineSecondary, PointInTimeRestore, Recovery, Restore, RestoreExternalBackup, RestoreExternalBackupSecondary, RestoreLongTermRetentionBackup or Secondary, and requires its matching source argument — creation_source_database_id for Copy/OnlineSecondary/Secondary/PointInTimeRestore (a full ARM ID of the source database; a copy of a database created in the same invocation is impossible in one input map: split them across two module calls and wire the ID from the database_ids output), restore_point_in_time for PointInTimeRestore, recover_database_id for Recovery, restore_dropped_database_id for Restore, restore_long_term_retention_backup_id for the LTR restore. max_size_gb must be at least 0.1 and cannot be set on Secondary/OnlineSecondary (they inherit the source's size); storage_account_type must be Geo, GeoZone, Local or Zone (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        for db_key, db in server.databases : [
          db.elastic_pool_key == null || contains(keys(server.elastic_pools), db.elastic_pool_key),
          db.elastic_pool_key == null || db.sku_name == "ElasticPool"
        ]
      ]
    ]))
    error_message = "databases elastic_pool_key must reference a sibling elastic_pools key of the same server entry, and when set the database's sku_name must be \"ElasticPool\" — a pooled database carries no per-database SKU; any other sku_name fails at apply."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        for db_key, db in server.databases : [
          db.short_term_retention_policy == null || (db.short_term_retention_policy.retention_days >= 1 && db.short_term_retention_policy.retention_days <= 35 && (db.short_term_retention_policy.backup_interval_in_hours == null || contains([12, 24], db.short_term_retention_policy.backup_interval_in_hours))),
          db.long_term_retention_policy == null || (
            (db.long_term_retention_policy.weekly_retention == null || can(regex("^P", db.long_term_retention_policy.weekly_retention)))
            && (db.long_term_retention_policy.monthly_retention == null || can(regex("^P", db.long_term_retention_policy.monthly_retention)))
            && (db.long_term_retention_policy.yearly_retention == null || can(regex("^P", db.long_term_retention_policy.yearly_retention)))
            && (db.long_term_retention_policy.week_of_year == null || (db.long_term_retention_policy.week_of_year >= 1 && db.long_term_retention_policy.week_of_year <= 52))
          )
        ]
      ]
    ]))
    error_message = "databases retention: short_term_retention_policy.retention_days must be 1–35 with backup_interval_in_hours 12 or 24 when set; long_term_retention_policy weekly/monthly/yearly_retention are ISO-8601 durations (e.g. \"P1Y\", \"P1M\", \"P1W\", \"P7D\") and week_of_year must be 1–52 when set."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        for group_key, group in server.failover_groups : [
          can(regex("^/", group.partner_server_id)),
          contains(["Automatic", "Manual"], group.read_write_endpoint_failover_policy.mode),
          group.read_write_endpoint_failover_policy.mode != "Automatic" || (group.read_write_endpoint_failover_policy.grace_minutes != null && group.read_write_endpoint_failover_policy.grace_minutes >= 1),
          alltrue([for db_key in group.database_keys : contains(keys(server.databases), db_key)])
        ]
      ]
    ]))
    error_message = "failover_groups: partner_server_id must be a full ARM resource ID of the partner (secondary) server — pass one from a second module invocation's server_ids output (see Notes); read_write_endpoint_failover_policy.mode must be Automatic or Manual (case-sensitive) with grace_minutes ≥ 1 required for Automatic; database_keys entries must reference sibling databases keys of the same server entry."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        for rule in server.firewall_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.start_ip_address)) && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.end_ip_address))
      ]
    ]))
    error_message = "firewall_rules start_ip_address and end_ip_address must be bare IPv4 addresses (no CIDR suffix) — Azure takes a range start-to-end; \"0.0.0.0\" for both is the special \"allow all Azure services\" rule (see Notes)."
  }

  validation {
    condition = alltrue(concat(
      [for server_key in keys(var.sql_servers) : !can(regex("\\.", server_key))],
      flatten([
        for server in var.sql_servers : [
          for child_key in concat(keys(server.elastic_pools), keys(server.databases), keys(server.firewall_rules), keys(server.failover_groups)) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of sql_servers and its nested elastic_pools, databases, firewall_rules and failover_groups maps must not contain \".\" — server keys are composed into child identifiers of the form \"<server_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        length(distinct([for pool in server.elastic_pools : lower(pool.name)])) == length(server.elastic_pools),
        length(distinct([for database in server.databases : lower(database.name)])) == length(server.databases),
        length(distinct([for rule in server.firewall_rules : lower(rule.name)])) == length(server.firewall_rules),
        length(distinct([for group in server.failover_groups : lower(group.name)])) == length(server.failover_groups)
      ]
    ]))
    error_message = "names must be unique within their server, case-insensitively — database, elastic pool, firewall rule and failover group names share the server's namespace at the Azure API."
  }

  validation {
    condition = alltrue(flatten([
      for server in var.sql_servers : [
        length(server.tags) <= 50 && alltrue([for k, v in server.tags : length(k) <= 512 && length(v) <= 256]),
        alltrue([for pool in server.elastic_pools : length(pool.tags) <= 50 && alltrue([for k, v in pool.tags : length(k) <= 512 && length(v) <= 256])]),
        alltrue([for database in server.databases : length(database.tags) <= 50 && alltrue([for k, v in database.tags : length(k) <= 512 && length(v) <= 256])]),
        alltrue([for group in server.failover_groups : length(group.tags) <= 50 && alltrue([for k, v in group.tags : length(k) <= 512 && length(v) <= 256])])
      ]
    ]))
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits) — checked on the server and on each elastic pool, database and failover group."
  }
}
