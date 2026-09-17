variable "credentials" {
  description = "Map of STACKIT Observability credentials keyed by an arbitrary identifier. Each entry creates one write credential on the given Observability instance. Username and password are both API-generated and only available at creation — see the module README."
  type = map(object({
    project_id          = string
    instance_id         = string
    description         = optional(string)
    rotate_when_changed = optional(map(string))
  }))

  validation {
    condition     = alltrue([for c in var.credentials : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.instance_id))])
    error_message = "project_id and instance_id must be UUIDs."
  }
}
