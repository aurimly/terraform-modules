variable "zone_id" {
  description = "Cloudflare zone ID the records belong to."
  type        = string
}

variable "records" {
  description = "Map of DNS records keyed by an arbitrary unique identifier (needed because records like CAA share the name '@'). Exactly one of content or data must be set per record."
  type = map(object({
    name     = string
    type     = string
    content  = optional(string)
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    priority = optional(number)
    comment  = optional(string)
    tags     = optional(set(string), [])
    data = optional(object({
      priority       = optional(number)
      target         = optional(string)
      flags          = optional(number)
      tag            = optional(string)
      value          = optional(string)
      algorithm      = optional(number)
      certificate    = optional(string)
      key_tag        = optional(number)
      type           = optional(number)
      protocol       = optional(number)
      public_key     = optional(string)
      digest         = optional(string)
      digest_type    = optional(number)
      altitude       = optional(number)
      lat_degrees    = optional(number)
      lat_direction  = optional(string)
      lat_minutes    = optional(number)
      lat_seconds    = optional(number)
      long_degrees   = optional(number)
      long_direction = optional(string)
      long_minutes   = optional(number)
      long_seconds   = optional(number)
      precision_horz = optional(number)
      precision_vert = optional(number)
      size           = optional(number)
      order          = optional(number)
      preference     = optional(number)
      regex          = optional(string)
      replacement    = optional(string)
      service        = optional(string)
      matching_type  = optional(number)
      selector       = optional(number)
      usage          = optional(number)
      port           = optional(number)
      weight         = optional(number)
      fingerprint    = optional(string)
    }))
    settings = optional(object({
      flatten_cname = optional(bool)
      ipv4_only     = optional(bool)
      ipv6_only     = optional(bool)
    }))
    private_routing = optional(bool)
  }))

  validation {
    condition     = alltrue([for r in var.records : (r.content == null) != (r.data == null)])
    error_message = "each record must set exactly one of content or data."
  }
}
