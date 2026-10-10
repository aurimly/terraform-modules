variable "redis_caches" {
  description = "Map of Azure Redis caches keyed by an arbitrary identifier. Each entry creates one azurerm_redis_cache in the named resource group; cache names are globally unique across all of Azure. Nested firewall rules and patch schedules wire into the cache resources this module creates itself."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    capacity            = number
    family              = string
    sku_name            = string

    redis_version                 = optional(string, "6")
    non_ssl_port_enabled          = optional(bool, false)
    minimum_tls_version           = optional(string, "1.2")
    public_network_access_enabled = optional(bool, true)

    access_keys_authentication_enabled = optional(bool)

    subnet_id                 = optional(string)
    private_static_ip_address = optional(string)
    shard_count               = optional(number)
    replicas_per_master       = optional(number)
    replicas_per_primary      = optional(number)

    tenant_settings = optional(map(string), {})
    zones           = optional(list(string), [])

    redis_configuration = optional(object({
      aof_backup_enabled                      = optional(bool)
      aof_storage_connection_string_0         = optional(string)
      aof_storage_connection_string_1         = optional(string)
      rdb_backup_enabled                      = optional(bool)
      rdb_backup_frequency                    = optional(number)
      rdb_backup_max_snapshot_count           = optional(number)
      rdb_storage_connection_string           = optional(string)
      storage_account_subscription_id         = optional(string)
      data_persistence_authentication_method  = optional(string)
      authentication_enabled                  = optional(bool)
      active_directory_authentication_enabled = optional(bool)
      maxmemory_reserved                      = optional(number)
      maxmemory_delta                         = optional(number)
      maxmemory_policy                        = optional(string)
      maxfragmentationmemory_reserved         = optional(number)
      notify_keyspace_events                  = optional(string)
    }))

    patch_schedule = optional(map(object({
      day_of_week        = string
      start_hour_utc     = optional(number)
      maintenance_window = optional(string)
    })), {})

    firewall_rules = optional(map(object({
      name     = string
      start_ip = string
      end_ip   = string
    })), {})

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for cache in var.redis_caches : can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", cache.name))
    ])
    error_message = "name must be 2–63 characters, lowercase alphanumerics and hyphens only — starting and ending alphanumeric; the name is globally unique across all of Azure, which the module cannot check: a claimed name fails at apply."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : contains(["Basic", "Standard", "Premium"], cache.sku_name)
    ])
    error_message = "sku_name must be Basic, Standard or Premium (case-sensitive) — downgrading the SKU forces replacement."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : contains(["C", "P"], cache.family)
    ])
    error_message = "family must be \"C\" (for Basic/Standard) or \"P\" (for Premium)."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      (cache.family == "C" ? contains(["Basic", "Standard"], cache.sku_name) : cache.sku_name == "Premium")
    ])
    error_message = "family and sku_name pair up: family \"C\" pairs with Basic/Standard, family \"P\" pairs with Premium — the pairing is enforced at the Azure API."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.capacity >= 0 && (cache.family == "C" ? cache.capacity <= 6 : cache.capacity >= 1 && cache.capacity <= 5)
    ])
    error_message = "capacity ranges by family: \"C\" 0–6, \"P\" 1–5 — the size of the cache to deploy."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : contains(["4", "6"], cache.redis_version)
    ])
    error_message = "redis_version must be \"4\" or \"6\" — version 4 no longer supports creating new instances on most regions; \"6\" is the default."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : cache.minimum_tls_version == "1.2"
    ])
    error_message = "minimum_tls_version must be \"1.2\" — the only value the API accepts anymore (TLS 1.0/1.1 retired across Azure)."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.subnet_id == null || (cache.sku_name == "Premium" && can(regex("^/", cache.subnet_id)))
    ])
    error_message = "subnet_id is only available with the Premium SKU and must be a full ARM resource ID (starting with \"/\") — a subnet hosting Azure Cache instances exclusively; changing it forces replacement."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : cache.private_static_ip_address == null || cache.subnet_id != null
    ])
    error_message = "private_static_ip_address implies subnet_id — the static IP is assigned inside the subnet the cache deploys into; changing it forces replacement."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : cache.shard_count == null || cache.sku_name == "Premium"
    ])
    error_message = "shard_count is only available with the Premium SKU — the number of shards on the Redis cluster."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : cache.replicas_per_master == null || cache.sku_name == "Premium"
    ])
    error_message = "replicas_per_master is only available with the Premium SKU."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : !(cache.shard_count != null && cache.replicas_per_master != null)
    ])
    error_message = "shard_count and replicas_per_master are mutually exclusive at the Azure API — pick the shard layout or the replica count, not both."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : cache.replicas_per_primary == null || cache.replicas_per_master == null || cache.replicas_per_primary == cache.replicas_per_master
    ])
    error_message = "when both replicas_per_primary and replicas_per_master are set they must be equal — the two arguments describe the same replica count across API generations."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.redis_configuration == null || cache.redis_configuration.authentication_enabled != false || cache.subnet_id != null
    ])
    error_message = "redis_configuration.authentication_enabled = false (no-auth access) requires subnet_id — unauthenticated caches only work inside a private subnet."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.access_keys_authentication_enabled != false || (cache.redis_configuration != null && cache.redis_configuration.active_directory_authentication_enabled == true)
    ])
    error_message = "access_keys_authentication_enabled = false requires redis_configuration.active_directory_authentication_enabled = true — Entra-only caches keep that as the one access path."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.redis_configuration == null || (
        cache.redis_configuration.aof_backup_enabled != true || cache.redis_configuration.aof_storage_connection_string_0 != null
      )
    ])
    error_message = "redis_configuration.aof_storage_connection_string_0 is required when aof_backup_enabled = true — AOF persistence writes to the first storage connection string."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.redis_configuration == null || (
        cache.redis_configuration.rdb_backup_enabled != true || cache.redis_configuration.rdb_storage_connection_string != null
      )
    ])
    error_message = "redis_configuration.rdb_storage_connection_string is required when rdb_backup_enabled = true — RDB persistence snapshots to the storage connection string (see Notes on the API's returned-value bug)."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.redis_configuration == null || cache.sku_name == "Premium" || (
        cache.redis_configuration.aof_backup_enabled != true && cache.redis_configuration.rdb_backup_enabled != true
      )
    ])
    error_message = "AOF and RDB persistence are Premium features — aof_backup_enabled and rdb_backup_enabled require sku_name = \"Premium\"."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.redis_configuration == null || cache.redis_configuration.rdb_backup_frequency == null || contains([15, 30, 60, 360, 720, 1440], cache.redis_configuration.rdb_backup_frequency)
    ])
    error_message = "redis_configuration.rdb_backup_frequency must be one of 15, 30, 60, 360, 720 or 1440 minutes."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.redis_configuration == null || cache.redis_configuration.data_persistence_authentication_method == null || contains(["SAS", "ManagedIdentity"], cache.redis_configuration.data_persistence_authentication_method)
    ])
    error_message = "redis_configuration.data_persistence_authentication_method must be \"SAS\" or \"ManagedIdentity\"."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches : alltrue([for zone in cache.zones : contains(["1", "2", "3"], zone)])
    ])
    error_message = "zones entries must be \"1\", \"2\" or \"3\" — availability-zone support is region-dependent; changing zones forces replacement."
  }

  validation {
    condition = alltrue(flatten([
      for cache in var.redis_caches : [
        for schedule in cache.patch_schedule :
        contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.day_of_week)
        && (schedule.start_hour_utc == null || (schedule.start_hour_utc >= 0 && schedule.start_hour_utc <= 23))
        && (schedule.maintenance_window == null || can(regex("^PT", schedule.maintenance_window)))
      ]
    ]))
    error_message = "patch_schedule: day_of_week is a full weekday name (Monday..Sunday), start_hour_utc 0–23 and maintenance_window an ISO 8601 timespan (\"PT5H\" — the default)."
  }

  validation {
    condition = alltrue(flatten([
      for cache in var.redis_caches : [
        for rule in cache.firewall_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.start_ip)) && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.end_ip))
      ]
    ]))
    error_message = "firewall_rules start_ip and end_ip must be bare IPv4 addresses (no CIDR suffix) — the rule range runs start-to-end."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      cache.identity == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], cache.identity.type) || alltrue([for id in coalesce(cache.identity.identity_ids, []) : can(regex("^/", id))])
    ])
    error_message = "identity.identity_ids is required when identity.type includes UserAssigned — full ARM resource IDs of user-assigned managed identities."
  }

  validation {
    condition = alltrue(concat(
      [for cache_key in keys(var.redis_caches) : !can(regex("\\.", cache_key))],
      flatten([
        for cache in var.redis_caches : [
          for child_key in concat(keys(cache.firewall_rules), keys(cache.patch_schedule)) : !can(regex("\\.", child_key))
        ]
      ])
    ))
    error_message = "map keys of redis_caches and its nested firewall_rules and patch_schedule maps must not contain \".\" — cache keys are composed into child identifiers of the form \"<cache_key>.<child_key>\"; dots would make outputs ambiguous and composite keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for cache_key, cache in var.redis_caches : [
        for other_key, other in var.redis_caches :
        cache_key == other_key || lower(cache.name) != lower(other.name)
      ]
    ]))
    error_message = "cache names must be unique across entries, case-insensitively — the name is globally unique and case-insensitive at the Azure API."
  }

  validation {
    condition = alltrue(flatten([
      for cache in var.redis_caches : [
        length(distinct([for rule in cache.firewall_rules : rule.name])) == length(cache.firewall_rules)
      ]
    ]))
    error_message = "firewall rule names must be unique within their cache — they live under the cache's naming scope at the Azure API."
  }

  validation {
    condition = alltrue([
      for cache in var.redis_caches :
      length(cache.tags) <= 50 && alltrue([for tag_key, tag_value in cache.tags : length(tag_key) <= 512 && length(tag_value) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}

variable "linked_servers" {
  description = "Map of Redis geo-replication links between two Premium caches defined in redis_caches. Each entry creates one azurerm_redis_linked_server on the target cache. server_role describes the role the linked (non-target) cache takes in the pair."
  default     = {}
  type = map(object({
    target_cache_key = string
    linked_cache_key = string
    server_role      = string
  }))

  validation {
    condition = alltrue([
      for entry in var.linked_servers : contains(["Primary", "Secondary"], entry.server_role)
    ])
    error_message = "server_role must be \"Primary\" or \"Secondary\" — the role of the linked (non-target) cache in the geo-replication pair."
  }

  validation {
    condition = alltrue([
      for entry in var.linked_servers : entry.target_cache_key != entry.linked_cache_key
    ])
    error_message = "target_cache_key and linked_cache_key must name two different caches — a cache cannot geo-replicate against itself."
  }

  validation {
    condition = alltrue([
      for entry in var.linked_servers :
      can(var.redis_caches[entry.target_cache_key]) && can(var.redis_caches[entry.linked_cache_key])
    ])
    error_message = "target_cache_key and linked_cache_key must each reference an existing redis_caches key — geo-replication links wire between caches this module creates."
  }

  validation {
    condition = alltrue([
      for entry in var.linked_servers :
      !can(var.redis_caches[entry.target_cache_key]) || !can(var.redis_caches[entry.linked_cache_key]) ||
      (
        var.redis_caches[entry.target_cache_key].sku_name == "Premium"
        && var.redis_caches[entry.linked_cache_key].sku_name == "Premium"
        && var.redis_caches[entry.target_cache_key].capacity == var.redis_caches[entry.linked_cache_key].capacity
        && var.redis_caches[entry.target_cache_key].family == var.redis_caches[entry.linked_cache_key].family
      )
    ])
    error_message = "both caches participating in a geo-replication pair must be Premium and the same size — matching capacity and family (the Azure API rejects unequal pairs on linked servers)."
  }
}
