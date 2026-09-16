variable "dns_authorizations" {
  default     = {}
  description = "Map of Certificate Manager DNS authorizations keyed by an arbitrary identifier. Each entry creates one google_certificate_manager_dns_authorization."
  type = map(object({
    name            = string
    domain          = string
    location        = optional(string, "global")
    project_id      = optional(string)
    description     = optional(string)
    labels          = optional(map(string), {})
    type            = optional(string)
    deletion_policy = optional(string)
  }))

  validation {
    condition     = alltrue([for a in var.dns_authorizations : can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,63}$", a.name))])
    error_message = "name must be 1 to 64 characters, start with a letter and contain only letters, digits, underscores and hyphens."
  }

  validation {
    condition     = alltrue([for a in var.dns_authorizations : can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9](\\.[a-z0-9-]+)+$", a.domain)) || can(regex("^\\*\\.[a-z0-9-]+(\\.[a-z0-9-]+)+$", a.domain))])
    error_message = "domain must be a hostname (e.g. example.com) or a wildcard hostname (*.example.com)."
  }

  validation {
    condition     = alltrue([for a in var.dns_authorizations : can(regex("^[a-z0-9-]+$", a.location))])
    error_message = "location must look like a GCP region (e.g. us-central1) or the value global; it is a shape check, not a list of valid locations."
  }

  validation {
    condition     = alltrue([for a in var.dns_authorizations : a.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", a.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for a in var.dns_authorizations : a.type == null || contains(["FIXED_RECORD", "PER_PROJECT_RECORD"], a.type)])
    error_message = "type must be FIXED_RECORD or PER_PROJECT_RECORD. Defaults to FIXED_RECORD (global) or PER_PROJECT_RECORD (regional) when unset."
  }

  validation {
    condition     = alltrue([for a in var.dns_authorizations : a.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], a.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }
}

variable "certificates" {
  default     = {}
  description = "Map of Certificate Manager certificates keyed by an arbitrary identifier. Each entry creates one google_certificate_manager_certificate (managed xor self_managed)."
  type = map(object({
    name            = string
    location        = optional(string, "global")
    project_id      = optional(string)
    description     = optional(string)
    labels          = optional(map(string), {})
    scope           = optional(string)
    deletion_policy = optional(string)
    managed = optional(object({
      domains            = list(string)
      dns_authorizations = optional(list(string), [])
      issuance_config    = optional(string)
    }))
    self_managed = optional(object({
      pem_certificate = string
      pem_private_key = string
    }))
  }))

  validation {
    condition     = alltrue([for c in var.certificates : can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,63}$", c.name))])
    error_message = "name must be 1 to 64 characters, start with a letter and contain only letters, digits, underscores and hyphens."
  }

  validation {
    condition     = alltrue([for c in var.certificates : (c.managed != null) != (c.self_managed != null)])
    error_message = "set exactly one of managed or self_managed."
  }

  validation {
    condition = alltrue([
      for c in var.certificates : c.managed == null || (
        length(c.managed.domains) > 0 &&
        length(c.managed.domains) <= 100 &&
        alltrue([for d in c.managed.domains : can(regex("^(\\*\\.)?([a-z0-9]([a-z0-9-]*[a-z0-9])?)(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", d))]) &&
        (c.managed.issuance_config == null || length(c.managed.dns_authorizations) == 0)
      )
    ])
    error_message = "managed needs 1 to 100 domains (letters/digits/hyphens or wildcard *.example.com), and exactly one of dns_authorizations (keys into dns_authorizations) or issuance_config (full resource id, bring-your-own)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.scope == null || contains(["DEFAULT", "EDGE_CACHE", "ALL_REGIONS", "CLIENT_AUTH"], c.scope)])
    error_message = "scope must be DEFAULT, EDGE_CACHE, ALL_REGIONS or CLIENT_AUTH. Defaults to DEFAULT when unset."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.deletion_policy == null || contains(["DELETE", "ABANDON", "PREVENT"], c.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, ABANDON or PREVENT. Defaults to DELETE when unset."
  }
}

variable "certificate_maps" {
  default     = {}
  description = "Map of Certificate Manager certificate maps keyed by an arbitrary identifier. Each entry creates one google_certificate_manager_certificate_map."
  type = map(object({
    name        = string
    project_id  = optional(string)
    description = optional(string)
    labels      = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for m in var.certificate_maps : can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,63}$", m.name))])
    error_message = "name must be 1 to 64 characters, start with a letter and contain only letters, digits, underscores and hyphens."
  }

  validation {
    condition     = alltrue([for m in var.certificate_maps : m.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", m.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "certificate_map_entries" {
  default     = {}
  description = "Map of Certificate Manager certificate map entries keyed by an arbitrary identifier. Each entry creates one google_certificate_manager_certificate_map_entry referencing one certificate_maps entry (map_key) and a set of certificates entries."
  type = map(object({
    map_key      = string
    name         = string
    project_id   = optional(string)
    description  = optional(string)
    hostname     = optional(string)
    matcher      = optional(string)
    labels       = optional(map(string), {})
    certificates = list(string)
  }))

  validation {
    condition     = alltrue([for e in var.certificate_map_entries : can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,63}$", e.name))])
    error_message = "name must be 1 to 64 characters, start with a letter and contain only letters, digits, underscores and hyphens."
  }

  validation {
    condition     = alltrue([for e in var.certificate_map_entries : e.matcher == null || contains(["PRIMARY"], e.matcher)])
    error_message = "matcher must be PRIMARY (SNI selection is the default behavior when matcher is unset and hostname is set)."
  }

  validation {
    condition     = alltrue([for e in var.certificate_map_entries : e.hostname == null || e.matcher == null])
    error_message = "an entry with a hostname selects by SNI and must not set matcher = PRIMARY; leave matcher unset for SNI entries."
  }

  validation {
    condition = alltrue([
      for e in var.certificate_map_entries : length(e.certificates) >= 1 && length(e.certificates) <= 15
    ])
    error_message = "certificates takes 1 to 15 keys into the certificates map (plan-fail if a key is missing)."
  }

  validation {
    condition = alltrue([
      for map_key in distinct([for _, e in var.certificate_map_entries : e.map_key]) : length([
        for _, e in var.certificate_map_entries
        : e.name if e.map_key == map_key && (e.matcher == "PRIMARY" || (e.matcher == null && e.hostname == null))
      ]) <= 1
    ])
    error_message = "at most one PRIMARY entry per certificate map (the API rejects multiple PRIMARY entries in the same map)."
  }
}
