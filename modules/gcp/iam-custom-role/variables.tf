variable "organization_roles" {
  description = "Map of organization-level custom IAM roles keyed by an arbitrary identifier. Each entry creates one google_organization_iam_custom_role."
  type = map(object({
    org_id      = string
    role_id     = string
    title       = string
    description = optional(string)
    permissions = list(string)
    stage       = optional(string)
  }))

  validation {
    condition     = alltrue([for k, r in var.organization_roles : can(regex("^[0-9]+$", r.org_id))])
    error_message = "org_id must be the bare numeric organization id (e.g. 123456789012), not organizations/<org_id>."
  }

  validation {
    condition     = alltrue([for k, r in var.organization_roles : can(regex("^[a-zA-Z][a-zA-Z0-9_.]{2,63}$", r.role_id))])
    error_message = "role_id must be 3-64 characters: letters, digits, underscores or periods, starting with a letter. It cannot contain hyphens, and cannot use a google- or iam-reserved prefix (e.g. google* and iam*; enforced by the API)."
  }

  validation {
    condition     = alltrue([for k, r in var.organization_roles : length(r.title) > 0 && length(r.title) <= 100])
    error_message = "title must be non-empty and at most 100 characters."
  }

  validation {
    condition     = alltrue([for k, r in var.organization_roles : length(r.permissions) > 0])
    error_message = "permissions must contain at least one permission."
  }

  validation {
    condition     = alltrue([for k, r in var.organization_roles : alltrue([for p in r.permissions : can(regex("^[a-z0-9-]+\\.[a-zA-Z0-9_]+\\.[a-zA-Z]+$", p))])])
    error_message = "permissions entries must look like <service>.<resource>.<verb> (e.g. storage.buckets.get); a shape check only — the API rejects unknown permissions at apply."
  }

  validation {
    condition     = alltrue([for k, r in var.organization_roles : r.stage == null || contains(["EAP", "ALPHA", "BETA", "GA", "DEPRECATED", "DISABLED"], r.stage)])
    error_message = "stage must be one of EAP, ALPHA, BETA, GA, DEPRECATED or DISABLED (case-sensitive)."
  }
}

variable "project_roles" {
  description = "Map of project-level custom IAM roles keyed by an arbitrary identifier. Each entry creates one google_project_iam_custom_role."
  type = map(object({
    project_id  = optional(string)
    role_id     = string
    title       = string
    description = optional(string)
    permissions = list(string)
    stage       = optional(string)
  }))

  validation {
    condition     = alltrue([for k, r in var.project_roles : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, r in var.project_roles : can(regex("^[a-zA-Z][a-zA-Z0-9_.]{2,63}$", r.role_id))])
    error_message = "role_id must be 3-64 characters: letters, digits, underscores or periods, starting with a letter. It cannot contain hyphens, and cannot use a google- or iam-reserved prefix (enforced by the API)."
  }

  validation {
    condition     = alltrue([for k, r in var.project_roles : length(r.title) > 0 && length(r.title) <= 100])
    error_message = "title must be non-empty and at most 100 characters."
  }

  validation {
    condition     = alltrue([for k, r in var.project_roles : length(r.permissions) > 0])
    error_message = "permissions must contain at least one permission."
  }

  validation {
    condition     = alltrue([for k, r in var.project_roles : alltrue([for p in r.permissions : can(regex("^[a-z0-9-]+\\.[a-zA-Z0-9_]+\\.[a-zA-Z]+$", p))])])
    error_message = "permissions entries must look like <service>.<resource>.<verb> (e.g. storage.buckets.get); a shape check only — the API rejects unknown permissions at apply."
  }

  validation {
    condition     = alltrue([for k, r in var.project_roles : r.stage == null || contains(["EAP", "ALPHA", "BETA", "GA", "DEPRECATED", "DISABLED"], r.stage)])
    error_message = "stage must be one of EAP, ALPHA, BETA, GA, DEPRECATED or DISABLED (case-sensitive)."
  }
}
