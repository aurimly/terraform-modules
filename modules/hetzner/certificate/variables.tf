variable "certificates" {
  description = "Map of Hetzner Cloud TLS certificates keyed by an arbitrary identifier. Each entry creates either a Hetzner-managed certificate (set domain_names) or an uploaded certificate (set private_key and certificate); an entry must be exactly one of the two."
  type = map(object({
    name         = string
    domain_names = optional(list(string))
    private_key  = optional(string)
    certificate  = optional(string)
    labels       = optional(map(string), {})
  }))

  validation {
    condition     = length(distinct([for cert in var.certificates : cert.name])) == length(var.certificates)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition     = alltrue([for cert in var.certificates : (cert.private_key != null) != (cert.domain_names != null)])
    error_message = "exactly one of private_key (uploaded certificate) or domain_names (managed certificate) must be set per entry."
  }

  validation {
    condition     = alltrue([for cert in var.certificates : cert.private_key == null || cert.certificate != null])
    error_message = "an uploaded certificate requires the PEM certificate."
  }

  validation {
    condition     = alltrue([for cert in var.certificates : cert.private_key != null || cert.certificate == null])
    error_message = "certificate is computed for managed certificates; do not set it."
  }

  validation {
    condition     = alltrue([for cert in var.certificates : cert.domain_names == null || length(cert.domain_names) > 0])
    error_message = "a managed certificate requires at least one domain name."
  }

  validation {
    condition     = alltrue([for cert in var.certificates : alltrue([for k in keys(cert.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) && length(k) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for cert in var.certificates : alltrue([for v in cert.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
