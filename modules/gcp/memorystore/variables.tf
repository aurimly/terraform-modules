variable "instances" {
  description = "Map of Memorystore (Redis/Valkey) instances keyed by an arbitrary identifier. Each entry creates one google_redis_instance."
  type = map(object({
    name                    = string
    region                  = string
    memory_size_gb          = number
    redis_version           = string
    tier                    = optional(string, "STANDARD_HA")
    project_id              = optional(string)
    location_id             = optional(string)
    alternative_location_id = optional(string)
    connect_mode            = optional(string)
    reserved_ip_range       = optional(string)
    secondary_ip_range      = optional(string)
    authorized_network      = optional(string)
    display_name            = optional(string)
    labels                  = optional(map(string), {})
    redis_configs           = optional(map(string), {})
    auth_enabled            = optional(bool)
    transit_encryption_mode = optional(string)
    replica_count           = optional(number)
    read_replicas_mode      = optional(string)
    deletion_protection     = optional(bool, true)
    maintenance_policy = optional(object({
      day = string
      start_time = object({
        hours   = number
        minutes = optional(number)
      })
    }))
    persistence_config = optional(object({
      persistence_mode        = optional(string)
      rdb_snapshot_period     = optional(string)
      rdb_snapshot_start_time = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z]([-a-z0-9]{0,58}[a-z0-9])?$", i.name))])
    error_message = "name must be 1-60 characters: lowercase letters, digits or hyphens, starting and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : can(regex("^[a-z]+-[a-z]+[0-9]+$", i.region))])
    error_message = "region must be a valid GCP region name (e.g. europe-west1)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.memory_size_gb >= 1 && i.memory_size_gb <= 300])
    error_message = "memory_size_gb must be between 1 and 300."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : contains(["REDIS_5_0", "REDIS_6_X", "REDIS_7_0", "REDIS_7_2", "VALKEY_7_0", "VALKEY_7_2", "VALKEY_8_0"], i.redis_version)])
    error_message = "redis_version must be one of REDIS_5_0, REDIS_6_X, REDIS_7_0, REDIS_7_2, VALKEY_7_0, VALKEY_7_2 or VALKEY_8_0 (case-sensitive). Older versions are deprecated API-side; upgrades are in-place, downgrades are rejected."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : contains(["BASIC", "STANDARD_HA"], i.tier)])
    error_message = "tier must be BASIC or STANDARD_HA (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", i.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.connect_mode == null || contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], i.connect_mode)])
    error_message = "connect_mode must be DIRECT_PEERING or PRIVATE_SERVICE_ACCESS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : (i.reserved_ip_range == null && i.secondary_ip_range == null) || i.connect_mode == "PRIVATE_SERVICE_ACCESS"])
    error_message = "reserved_ip_range and secondary_ip_range require connect_mode = PRIVATE_SERVICE_ACCESS."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.secondary_ip_range == null || i.reserved_ip_range != null])
    error_message = "secondary_ip_range requires reserved_ip_range to be set."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.replica_count == null || i.tier == "STANDARD_HA"])
    error_message = "replica_count only applies to STANDARD_HA instances."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.replica_count == null || (i.replica_count >= 0 && i.replica_count <= 5)])
    error_message = "replica_count must be between 0 and 5 (1 without read replicas, 1-5 with read replicas enabled, server default 2)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.read_replicas_mode == null || contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], i.read_replicas_mode)])
    error_message = "read_replicas_mode must be READ_REPLICAS_DISABLED or READ_REPLICAS_ENABLED (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.auth_enabled != true || can(regex("^(REDIS_(6_X|7_0|7_2)|VALKEY_)", i.redis_version))])
    error_message = "auth_enabled requires REDIS_6_X or higher, or a VALKEY_* version."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.transit_encryption_mode == null || contains(["DISABLED", "SERVER_AUTHENTICATION"], i.transit_encryption_mode)])
    error_message = "transit_encryption_mode must be DISABLED or SERVER_AUTHENTICATION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.maintenance_policy == null || contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], i.maintenance_policy.day)])
    error_message = "maintenance_policy.day must be one of MONDAY through SUNDAY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.maintenance_policy == null || (i.maintenance_policy.start_time.hours >= 0 && i.maintenance_policy.start_time.hours <= 23 && (i.maintenance_policy.start_time.minutes == null || (i.maintenance_policy.start_time.minutes >= 0 && i.maintenance_policy.start_time.minutes <= 59)))])
    error_message = "maintenance_policy.start_time.hours must be 0-23 and minutes 0-59 (UTC)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.persistence_config == null || i.persistence_config.persistence_mode == null || contains(["DISABLED", "RDB"], i.persistence_config.persistence_mode)])
    error_message = "persistence_config.persistence_mode must be one of DISABLED or RDB (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, i in var.instances : i.persistence_config == null || i.persistence_config.persistence_mode != "RDB" || i.persistence_config.rdb_snapshot_period != null])
    error_message = "persistence_config.rdb_snapshot_period is required when persistence_mode is RDB."
  }
}
