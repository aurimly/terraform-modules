variable "projects" {
  description = "Map of GCP projects keyed by an arbitrary identifier. Each entry creates one project. A project must have either org_id or folder_id set as its parent."
  type = map(object({
    name                = string
    project_id          = string
    org_id              = optional(string)
    folder_id           = optional(string)
    billing_account     = string
    auto_create_network = optional(bool, false)
    deletion_policy     = optional(string, "PREVENT")
    labels              = optional(map(string), {})
    tags                = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for p in var.projects : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for p in var.projects : can(regex("^[A-Za-z0-9 !\"'-]{4,30}$", p.name))])
    error_message = "name must be 4 to 30 characters and contain only letters, digits, spaces, hyphens, single quotes, double quotes and exclamation points."
  }

  validation {
    condition     = alltrue([for p in var.projects : can(regex("^[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{6}$", p.billing_account))])
    error_message = "billing_account must be in the form XXXXXX-XXXXXX-XXXXXX (uppercase letters and digits)."
  }

  validation {
    condition     = alltrue([for p in var.projects : p.org_id == null || can(regex("^[0-9]+$", p.org_id))])
    error_message = "org_id must be the bare numeric organization ID (e.g. \"123456789012\")."
  }

  validation {
    condition     = alltrue([for p in var.projects : p.folder_id == null || can(regex("^([0-9]+|folders/[0-9]+)$", p.folder_id))])
    error_message = "folder_id must be a bare numeric folder ID or \"folders/<folder_id>\"."
  }

  validation {
    condition     = alltrue([for p in var.projects : (p.org_id == null) != (p.folder_id == null)])
    error_message = "each project must set exactly one of org_id or folder_id as its parent."
  }

  validation {
    condition     = alltrue([for p in var.projects : contains(["PREVENT", "ABANDON", "DELETE"], p.deletion_policy)])
    error_message = "deletion_policy must be one of PREVENT, ABANDON or DELETE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for p in var.projects : alltrue([for k, v in p.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])])
    error_message = "labels keys must start with a lowercase letter and contain only lowercase letters, digits, underscores and hyphens (1-63 chars); values the same charset (0-63 chars, may be empty)."
  }
}
