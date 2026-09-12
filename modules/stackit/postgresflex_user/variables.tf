variable "users" {
  description = "Map of STACKIT PostgreSQL Flex users keyed by an arbitrary identifier. Each entry creates one database user on the given instance. The password is API-generated and only available at creation — see the module README."
  type = map(object({
    project_id          = string
    instance_id         = string
    username            = string
    roles               = set(string)
    region              = optional(string)
    rotate_when_changed = optional(map(string))
  }))

  validation {
    condition     = alltrue([for u in var.users : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", u.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", u.instance_id))])
    error_message = "project_id and instance_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for u in var.users : length(u.username) >= 1])
    error_message = "username must be at least 1 character."
  }
}
