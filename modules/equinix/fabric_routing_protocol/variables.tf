variable "direct_protocols" {
  description = "Map of DIRECT routing protocols keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_routing_protocol with type DIRECT. At least one of direct_ipv4 or direct_ipv6 must be set."
  type = map(object({
    connection_uuid = string
    name            = string
    description     = optional(string)
    direct_ipv4 = optional(object({
      equinix_iface_ip = string
    }))
    direct_ipv6 = optional(object({
      equinix_iface_ip = string
    }))
  }))

  validation {
    condition     = alltrue([for p in var.direct_protocols : can(regex("^[a-zA-Z0-9_-]{1,24}$", p.name))])
    error_message = "name must be 1 to 24 characters, letters, digits, hyphens or underscores only."
  }

  validation {
    condition     = alltrue([for p in var.direct_protocols : p.direct_ipv4 != null || p.direct_ipv6 != null])
    error_message = "at least one of direct_ipv4 or direct_ipv6 must be set."
  }
}

variable "bgp_protocols" {
  description = "Map of BGP routing protocols keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_routing_protocol with type BGP. At least one of bgp_ipv4 or bgp_ipv6 must be set. Entries are created after every direct_protocols entry (the API requires the DIRECT protocol on a connection before BGP)."
  type = map(object({
    connection_uuid = string
    name            = string
    description     = optional(string)
    customer_asn    = number
    # Not sensitive-markable per-attribute inside a map variable; see the
    # README "Secrets in state" section.
    bgp_auth_key = optional(string)
    # Optional+Computed upstream; omitted means the provider default applies.
    as_override_enabled = optional(bool)
    bfd = optional(object({
      enabled = bool
      # String upstream (provider default 100): an int default on a string field.
      interval = optional(string)
    }))
    bgp_ipv4 = optional(object({
      customer_peer_ip = string
      enabled          = optional(bool)
      inbound_med      = optional(number)
      outbound_med     = optional(number)
      # String upstream, values 0, 1, 3 or 5.
      outbound_as_prepend_count = optional(string)
    }))
    bgp_ipv6 = optional(object({
      customer_peer_ip          = string
      enabled                   = optional(bool)
      inbound_med               = optional(number)
      outbound_med              = optional(number)
      outbound_as_prepend_count = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for p in var.bgp_protocols : can(regex("^[a-zA-Z0-9_-]{1,24}$", p.name))])
    error_message = "name must be 1 to 24 characters, letters, digits, hyphens or underscores only."
  }

  validation {
    condition     = alltrue([for p in var.bgp_protocols : p.customer_asn >= 1])
    error_message = "customer_asn must be a positive ASN."
  }

  validation {
    condition     = alltrue([for p in var.bgp_protocols : p.bgp_ipv4 != null || p.bgp_ipv6 != null])
    error_message = "at least one of bgp_ipv4 or bgp_ipv6 must be set."
  }

  validation {
    condition     = alltrue([for p in var.bgp_protocols : p.bgp_ipv4 == null || p.bgp_ipv4.outbound_as_prepend_count == null || contains(["0", "1", "3", "5"], p.bgp_ipv4.outbound_as_prepend_count)])
    error_message = "bgp_ipv4.outbound_as_prepend_count must be one of \"0\", \"1\", \"3\" or \"5\" (a string, per the provider schema)."
  }

  validation {
    condition     = alltrue([for p in var.bgp_protocols : p.bgp_ipv6 == null || p.bgp_ipv6.outbound_as_prepend_count == null || contains(["0", "1", "3", "5"], p.bgp_ipv6.outbound_as_prepend_count)])
    error_message = "bgp_ipv6.outbound_as_prepend_count must be one of \"0\", \"1\", \"3\" or \"5\" (a string, per the provider schema)."
  }

  validation {
    condition     = alltrue([for p in var.bgp_protocols : p.bfd == null || p.bfd.interval == null || can(tonumber(p.bfd.interval))])
    error_message = "bfd.interval must be a numeric string (the field is a string upstream; e.g. \"100\")."
  }
}
