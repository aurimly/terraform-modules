variable "databases" {
  description = "Map of Firestore databases keyed by an arbitrary identifier. Each entry creates one google_firestore_database."
  type = map(object({
    name                              = string
    location_id                       = string
    project_id                        = optional(string)
    type                              = string
    database_edition                  = optional(string)
    concurrency_mode                  = optional(string)
    app_engine_integration_mode       = optional(string)
    point_in_time_recovery_enablement = optional(string)
    delete_protection_state           = optional(string)
    deletion_policy                   = optional(string)
    cmek_config = optional(object({
      kms_key_name = string
    }))
    tags                                = optional(map(string))
    firestore_data_access_mode          = optional(string)
    mongodb_compatible_data_access_mode = optional(string)
    realtime_updates_mode               = optional(string)
  }))

  validation {
    condition     = alltrue([for d in var.databases : d.name == "(default)" || (can(regex("^[a-z][a-z0-9-]{3,62}$", d.name)) && !can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", d.name)))])
    error_message = "name must be \"(default)\" or a database id of 4 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not look like a UUID. Immutable; changing forces replacement."
  }

  validation {
    condition     = alltrue([for d in var.databases : contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], d.type)])
    error_message = "type must be one of FIRESTORE_NATIVE or DATASTORE_MODE."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.database_edition == null || contains(["STANDARD", "ENTERPRISE"], d.database_edition)
    ])
    error_message = "database_edition must be one of STANDARD or ENTERPRISE."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.database_edition != "ENTERPRISE" || d.type == "FIRESTORE_NATIVE"
    ])
    error_message = "database_edition ENTERPRISE requires type to be FIRESTORE_NATIVE."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.concurrency_mode == null || contains(["OPTIMISTIC", "PESSIMISTIC", "OPTIMISTIC_WITH_ENTITY_GROUPS"], d.concurrency_mode)
    ])
    error_message = "concurrency_mode must be one of OPTIMISTIC, PESSIMISTIC or OPTIMISTIC_WITH_ENTITY_GROUPS."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.app_engine_integration_mode == null || contains(["ENABLED", "DISABLED"], d.app_engine_integration_mode)
    ])
    error_message = "app_engine_integration_mode must be one of ENABLED or DISABLED."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.point_in_time_recovery_enablement == null || contains(["POINT_IN_TIME_RECOVERY_ENABLED", "POINT_IN_TIME_RECOVERY_DISABLED"], d.point_in_time_recovery_enablement)
    ])
    error_message = "point_in_time_recovery_enablement must be one of POINT_IN_TIME_RECOVERY_ENABLED or POINT_IN_TIME_RECOVERY_DISABLED."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.delete_protection_state == null || contains(["DELETE_PROTECTION_STATE_UNSPECIFIED", "DELETE_PROTECTION_ENABLED", "DELETE_PROTECTION_DISABLED"], d.delete_protection_state)
    ])
    error_message = "delete_protection_state must be one of DELETE_PROTECTION_STATE_UNSPECIFIED, DELETE_PROTECTION_ENABLED or DELETE_PROTECTION_DISABLED."
  }

  validation {
    condition = alltrue([
      for d in var.databases : d.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], d.deletion_policy)
    ])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON."
  }

  validation {
    condition = alltrue([
      for d in var.databases : (d.database_edition == "ENTERPRISE") || (d.firestore_data_access_mode == null && d.mongodb_compatible_data_access_mode == null && d.realtime_updates_mode == null)
    ])
    error_message = "firestore_data_access_mode, mongodb_compatible_data_access_mode and realtime_updates_mode can only be set for ENTERPRISE edition databases."
  }
}
