variable "host_projects" {
  description = "Map of Shared VPC host projects keyed by an arbitrary identifier. Each entry enables the project as a Shared VPC host and attaches its service projects to it. project_id is the subject project — there is no provider-project default."
  type = map(object({
    project_id              = string
    service_projects        = optional(list(string), [])
    host_deletion_policy    = optional(string)
    service_deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for k, h in var.host_projects : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", h.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, h in var.host_projects : alltrue([for sp in h.service_projects : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", sp))])])
    error_message = "service_projects entries must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, h in var.host_projects : !contains(h.service_projects, h.project_id)])
    error_message = "a project cannot be attached as a service project to its own host project."
  }

  validation {
    condition     = length(distinct(flatten([for k, h in var.host_projects : h.service_projects]))) == length(flatten([for k, h in var.host_projects : h.service_projects]))
    error_message = "service_projects must be globally unique across all host_projects entries; a project can be attached to at most one Shared VPC host."
  }

  validation {
    condition     = alltrue([for k, h in var.host_projects : h.host_deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], h.host_deletion_policy)])
    error_message = "host_deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for k, h in var.host_projects : h.service_deletion_policy == null || h.service_deletion_policy == "ABANDON"])
    error_message = "service_deletion_policy must be ABANDON (the only accepted value for service project attachments)."
  }
}
