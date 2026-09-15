variable "server_backup_schedules" {
  description = "Map of STACKIT server backup schedules keyed by an arbitrary identifier. Each entry creates one backup schedule for one server. Requires the backup service explicitly enabled via stackit/server_backup_enable (implicit enable from schedules is removed 26.09.2026). Schedules use RFC 5545 rrule format, not cron — see the module README."
  type = map(object({
    project_id = string
    server_id  = string
    name       = string
    rrule      = string
    enabled    = bool
    backup_properties = object({
      name             = string
      retention_period = number
      volume_ids       = optional(list(string))
    })
    region = optional(string)
  }))

  validation {
    condition     = alltrue([for s in var.server_backup_schedules : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.server_id))])
    error_message = "project_id and server_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for s in var.server_backup_schedules : length(s.name) >= 1 && length(s.name) <= 255])
    error_message = "name must be between 1 and 255 characters."
  }

  validation {
    condition     = alltrue([for s in var.server_backup_schedules : s.backup_properties.retention_period >= 1])
    error_message = "backup_properties.retention_period must be at least 1."
  }

  validation {
    condition     = alltrue([for s in var.server_backup_schedules : s.backup_properties.volume_ids == null || length(s.backup_properties.volume_ids) >= 1])
    error_message = "backup_properties.volume_ids must be non-empty when set."
  }
}
