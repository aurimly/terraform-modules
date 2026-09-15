variable "server_update_schedules" {
  description = "Map of STACKIT server update schedules keyed by an arbitrary identifier. Each entry creates one update schedule (with a maintenance window) for one server. Requires the update service explicitly enabled via stackit/server_update_enable (implicit enable from schedules is removed 28.09.2026). Schedules use RFC 5545 rrule format, not cron — see the module README."
  type = map(object({
    project_id         = string
    server_id          = string
    name               = string
    rrule              = string
    enabled            = bool
    maintenance_window = number
    region             = optional(string)
  }))

  validation {
    condition     = alltrue([for s in var.server_update_schedules : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.server_id))])
    error_message = "project_id and server_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for s in var.server_update_schedules : length(s.name) >= 1 && length(s.name) <= 255])
    error_message = "name must be between 1 and 255 characters."
  }

  validation {
    condition     = alltrue([for s in var.server_update_schedules : s.maintenance_window >= 1 && s.maintenance_window <= 24])
    error_message = "maintenance_window must be between 1 and 24."
  }
}
