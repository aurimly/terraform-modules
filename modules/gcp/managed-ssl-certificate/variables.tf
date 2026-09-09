variable "certificates" {
  description = "Map of Google-managed SSL certificates keyed by an arbitrary identifier. Each entry creates one google_compute_managed_ssl_certificate."
  type = map(object({
    name        = string
    project_id  = optional(string)
    description = optional(string)
    managed = object({
      domains = list(string)
    })
  }))

  validation {
    condition     = alltrue([for k, c in var.certificates : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", c.name))])
    error_message = "name must be a valid RFC1035 name: 1-63 lowercase letters, digits or dashes, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for k, c in var.certificates : c.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", c.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for k, c in var.certificates : length(c.managed.domains) > 0 && length(c.managed.domains) <= 100])
    error_message = "managed.domains must contain between 1 and 100 domains."
  }

  validation {
    condition     = alltrue([for k, c in var.certificates : alltrue([for d in c.managed.domains : can(regex("^(\\*\\.)?[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", d))])])
    error_message = "managed.domains entries must be valid hostnames (lowercase letters, digits, dots and dashes; an optional leading *. wildcard)."
  }
}
