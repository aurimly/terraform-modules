variable "records" {
  description = "Map of NS1 records keyed by an arbitrary unique identifier (records like CAA share the name '@'). `domain` defaults to \"<key>.<zone>\"; for zone-apex records set `domain` to the zone name (no trailing dot)."
  type = map(object({
    zone                     = string
    type                     = string
    domain                   = optional(string)
    ttl                      = optional(number, 3600)
    override_ttl             = optional(bool, false)
    link                     = optional(string)
    use_client_subnet        = optional(bool, true)
    meta                     = optional(map(string), {})
    tags                     = optional(map(string), {})
    blocked_tags             = optional(list(string))
    override_address_records = optional(bool)
    filters = optional(list(object({
      filter   = string
      disabled = optional(bool, false)
      config   = optional(map(string), {})
    })), [])
    regions = optional(list(object({
      name = string
      meta = optional(map(string), {})
    })), [])
    answers = optional(list(object({
      answer       = optional(string)
      answer_parts = optional(list(string))
      region       = optional(string)
      meta         = optional(map(string), {})
    })), [])
  }))

  validation {
    condition = alltrue(flatten([
      for r in var.records : [
        for a in r.answers : (a.answer != null) != (a.answer_parts != null)
      ]
    ]))
    error_message = "each answer must set exactly one of answer or answer_parts."
  }
}
