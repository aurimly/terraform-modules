variable "role_assignments" {
  description = "Map of STACKIT role assignments on the organization keyed by an arbitrary identifier. Each entry assigns one role to one subject."
  type = map(object({
    resource_id = string
    role        = string
    subject     = string
  }))

  validation {
    condition     = alltrue([for ra in var.role_assignments : ra.resource_id != ""])
    error_message = "resource_id must be set to the organization ID (UUID)."
  }

  validation {
    condition     = alltrue([for ra in var.role_assignments : ra.role != ""])
    error_message = "role must be set to the role name to assign (query available roles via stackit curl https://authorization.api.stackit.cloud/v2/{resourceType}/{resourceId}/roles)."
  }

  validation {
    condition     = alltrue([for ra in var.role_assignments : ra.subject == lower(ra.subject)])
    error_message = "subject must be lowercase (user email, service account email, or client name)."
  }

  validation {
    condition     = length(var.role_assignments) == length(distinct([for ra in var.role_assignments : "${ra.resource_id},${ra.role},${ra.subject}"]))
    error_message = "duplicate role assignment: the same (resource_id, role, subject) combination must not appear under more than one key (upstream rejects duplicate assignments)."
  }
}
