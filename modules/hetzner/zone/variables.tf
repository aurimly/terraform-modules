variable "zones" {
  description = "Map of Hetzner Cloud zones keyed by an arbitrary identifier. Each entry creates one zone. Zone resource names are scoped to the provider token (no per-zone project)."
  type = map(object({
    name              = string
    mode              = string
    ttl               = optional(number)
    labels            = optional(map(string), {})
    delete_protection = optional(bool)
    primary_nameservers = optional(list(object({
      address        = string
      port           = optional(number)
      tsig_algorithm = optional(string)
      tsig_key       = optional(string)
    })))
  }))

  validation {
    condition     = alltrue([for z in var.zones : length(z.name) >= 1 && length(z.name) <= 255 && !can(regex("\\.$", z.name)) && z.name == lower(z.name)])
    error_message = "name must be 1 to 255 characters, lowercase, without a trailing dot."
  }

  validation {
    condition     = length(distinct([for z in var.zones : z.name])) == length(var.zones)
    error_message = "zone names must be unique across map keys (duplicate names fail together at apply time)."
  }

  validation {
    condition     = alltrue([for z in var.zones : contains(["primary", "secondary"], z.mode)])
    error_message = "mode must be one of primary or secondary."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.ttl == null || (z.ttl >= 60 && z.ttl <= 2147483647)])
    error_message = "ttl must be between 60 and 2147483647 seconds when set."
  }

  validation {
    condition     = alltrue([for z in var.zones : !(z.mode == "primary" && z.primary_nameservers != null)])
    error_message = "primary_nameservers is forbidden when mode is primary."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.mode != "secondary" || (z.primary_nameservers != null && length(z.primary_nameservers) >= 1)])
    error_message = "primary_nameservers is required (at least one entry) when mode is secondary."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.primary_nameservers == null || length(distinct([for ns in z.primary_nameservers : ns.address])) == length(z.primary_nameservers)])
    error_message = "primary_nameserver addresses must be unique within each zone."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.primary_nameservers == null || alltrue([for ns in z.primary_nameservers : ns.tsig_algorithm == null || contains(["hmac-md5", "hmac-sha1", "hmac-sha256"], ns.tsig_algorithm)])])
    error_message = "primary_nameservers tsig_algorithm must be one of hmac-md5, hmac-sha1 or hmac-sha256."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.primary_nameservers == null || alltrue([for ns in z.primary_nameservers : ns.tsig_key == null || ns.tsig_algorithm != null])])
    error_message = "primary_nameservers tsig_key requires tsig_algorithm to be set in the same entry."
  }

  validation {
    condition     = alltrue([for z in var.zones : alltrue([for k in keys(z.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) && length(k) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for z in var.zones : alltrue([for v in z.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
