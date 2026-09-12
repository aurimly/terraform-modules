variable "users" {
  description = "Map of STACKIT Secrets Manager users keyed by an arbitrary identifier. Each entry creates one user on the given instance; username and password are API-generated. The password is only available at creation — see the module README."
  type = map(object({
    project_id          = string
    instance_id         = string
    description         = string
    write_enabled       = bool
    rotate_when_changed = optional(map(string))
  }))

  validation {
    condition     = alltrue([for u in var.users : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", u.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", u.instance_id))])
    error_message = "project_id and instance_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for u in var.users : length(u.description) >= 1])
    error_message = "description must be at least 1 character."
  }
}
