variable "instances" {
  description = "Map of STACKIT MongoDB Flex instances keyed by an arbitrary identifier. Each entry creates one instance in the given project and region."
  type = map(object({
    project_id = string
    name       = string
    acl        = list(string)
    flavor = object({
      cpu = number
      ram = number
    })
    replicas = number
    storage = object({
      class = string
      size  = number
    })
    version         = string
    backup_schedule = string
    options = object({
      type                              = string
      point_in_time_window_hours        = number
      snapshot_retention_days           = optional(number)
      daily_snapshot_retention_days     = optional(number)
      weekly_snapshot_retention_weeks   = optional(number)
      monthly_snapshot_retention_months = optional(number)
    })
    region = optional(string)
  }))

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", i.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for i in var.instances : can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", i.name))])
    error_message = "name must start with a lowercase letter and contain only lowercase letters, digits or hyphens, without a trailing hyphen."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.acl) >= 1 && alltrue([for cidr in i.acl : can(cidrhost(cidr, 0)) && can(regex("\\.", cidr))])])
    error_message = "acl must be a non-empty list of valid IPv4 CIDRs."
  }

  validation {
    condition     = alltrue([for i in var.instances : contains(["Replica", "Sharded", "Single"], i.options.type)])
    error_message = "options.type must be one of Replica, Sharded or Single."
  }

  validation {
    condition     = alltrue([for i in var.instances : i.storage.size >= 1])
    error_message = "storage.size must be at least 1."
  }

  validation {
    condition     = alltrue([for i in var.instances : length(i.backup_schedule) >= 1 && can(regex("^\\S+\\s+\\S+\\s+\\S+\\s+\\S+\\s+\\S+$", i.backup_schedule))])
    error_message = "backup_schedule must be a cron expression with five whitespace-separated fields (minute hour day-of-month month day-of-week)."
  }
}
