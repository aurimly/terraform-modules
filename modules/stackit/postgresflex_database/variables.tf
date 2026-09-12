variable "databases" {
  description = "Map of STACKIT PostgreSQL Flex databases keyed by an arbitrary identifier. Each entry creates one database inside an existing PostgreSQL Flex instance. owner must be an existing PostgresFlex user."
  type = map(object({
    project_id  = string
    instance_id = string
    name        = string
    owner       = string
    region      = optional(string)
  }))

  validation {
    condition     = alltrue([for d in var.databases : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", d.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", d.instance_id))])
    error_message = "project_id and instance_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for d in var.databases : length(d.name) >= 1 && length(d.owner) >= 1])
    error_message = "name and owner must be at least 1 character."
  }
}
