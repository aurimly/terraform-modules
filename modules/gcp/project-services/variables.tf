variable "services" {
  description = "Map of project API services keyed by an arbitrary identifier. Each entry enables one service in one project."
  type = map(object({
    service                    = string
    project_id                 = optional(string)
    disable_dependent_services = optional(bool, false)
    disable_on_destroy         = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for s in var.services : can(regex("^[a-z0-9-]+\\.googleapis\\.com$", s.service))])
    error_message = "service must be the full service form, e.g. pubsub.googleapis.com (the Service Usage API expects the full form)."
  }

  validation {
    condition     = alltrue([for s in var.services : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = length(distinct([for s in var.services : "${coalesce(s.project_id, "")}/${s.service}"])) == length(var.services)
    error_message = "each (project_id, service) pair must be unique across entries. Entries without project_id resolve to the provider default project, which cannot be deduplicated here — make sure no such entry duplicates a service enabled for the same project under a different key."
  }
}
