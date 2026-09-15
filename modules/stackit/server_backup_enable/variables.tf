variable "server_backup_enables" {
  description = "Map of STACKIT server backup enablements keyed by an arbitrary identifier. Each entry enables the backup service for one server. Destroy actually disables the service — see the module README."
  type = map(object({
    project_id       = string
    server_id        = string
    backup_policy_id = optional(string)
    region           = optional(string)
  }))

  validation {
    condition     = alltrue([for e in var.server_backup_enables : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", e.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", e.server_id))])
    error_message = "project_id and server_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for e in var.server_backup_enables : e.backup_policy_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", e.backup_policy_id))])
    error_message = "backup_policy_id must be a UUID."
  }
}
