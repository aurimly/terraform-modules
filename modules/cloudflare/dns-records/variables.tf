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
      flags = optional(number)
      tag   = string
      value = string
    }))
  }))

  validation {
    condition     = alltrue([for r in var.records : (r.content == null) != (r.data == null)])
    error_message = "each record must set exactly one of content or data."
  }
}
