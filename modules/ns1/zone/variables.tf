variable "zones" {
  description = "Map of NS1 zones keyed by zone name."
  type = map(object({
    ttl                    = optional(number, 3600)
    tags                   = optional(map(string), {})
    link                   = optional(string)
    primary                = optional(string)
    primary_port           = optional(number)
    primary_network        = optional(number)
    additional_primaries   = optional(list(string))
    additional_ports       = optional(list(number))
    additional_networks    = optional(list(number))
    additional_notify_only = optional(list(bool))
    hostmaster             = optional(string)
    refresh                = optional(number)
    retry                  = optional(number)
    expiry                 = optional(number)
    nx_ttl                 = optional(number)
    dnssec                 = optional(bool)
    autogenerate_ns_record = optional(bool, true)
    networks               = optional(set(number))
    secondaries = optional(list(object({
      ip     = string
      port   = optional(number, 53)
      notify = optional(bool, false)
    })), [])
    tsig             = optional(map(string))
    custom_primaries = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for z in var.zones :
      (z.primary != null ? 1 : 0) + (z.additional_primaries != null ? 1 : 0) + (length(z.secondaries) > 0 ? 1 : 0) <= 1
    ])
    error_message = "each zone must set at most one of primary, additional_primaries, secondaries."
  }
}
