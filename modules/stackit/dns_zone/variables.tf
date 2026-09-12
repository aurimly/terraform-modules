variable "zones" {
  description = "Map of STACKIT DNS zones keyed by an arbitrary identifier. Each entry creates one DNS zone in the given project."
  type = map(object({
    project_id      = string
    name            = string
    dns_name        = string
    type            = optional(string)
    acl             = optional(string)
    active          = optional(bool)
    contact_email   = optional(string)
    default_ttl     = optional(number)
    description     = optional(string)
    expire_time     = optional(number)
    is_reverse_zone = optional(bool)
    negative_cache  = optional(number)
    primaries       = optional(list(string))
    refresh_time    = optional(number)
    retry_time      = optional(number)
  }))

  validation {
    condition     = alltrue([for z in var.zones : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", z.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for z in var.zones : length(z.name) >= 1 && length(z.name) <= 63])
    error_message = "name must be 1 to 63 characters."
  }

  validation {
    condition     = alltrue([for z in var.zones : length(z.dns_name) >= 1 && length(z.dns_name) <= 253 && !can(regex("\\.$", z.dns_name))])
    error_message = "dns_name must be 1 to 253 characters and must not end with a trailing dot."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type == null || contains(["primary", "secondary"], z.type)])
    error_message = "type must be one of primary or secondary."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.acl == null || length(z.acl) <= 2000])
    error_message = "acl must be at most 2000 characters."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.contact_email == null || length(z.contact_email) <= 255])
    error_message = "contact_email must be at most 255 characters."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.description == null || length(z.description) <= 1024])
    error_message = "description must be at most 1024 characters."
  }

  validation {
    condition     = alltrue([for z in var.zones : alltrue([for t in [z.default_ttl, z.expire_time, z.refresh_time, z.retry_time, z.negative_cache] : t == null || (t >= 60 && t <= 99999999)])])
    error_message = "default_ttl, expire_time, refresh_time, retry_time and negative_cache must be between 60 and 99999999 seconds when set."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.primaries == null || length(z.primaries) <= 10])
    error_message = "primaries must contain at most 10 entries."
  }
}
