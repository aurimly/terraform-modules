variable "security_group_rules" {
  description = "Map of STACKIT security group rules keyed by an arbitrary identifier. Each entry creates one rule on an existing security group."
  type = map(object({
    project_id               = string
    region                   = optional(string)
    security_group_id        = string
    direction                = string
    description              = optional(string)
    ether_type               = optional(string)
    ip_range                 = optional(string)
    remote_security_group_id = optional(string)
    protocol_name            = optional(string)
    protocol_number          = optional(number)
    port_range = optional(object({
      min = number
      max = number
    }))
    icmp_parameters = optional(object({
      type = number
      code = number
    }))
  }))

  validation {
    condition     = alltrue([for r in var.security_group_rules : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.security_group_id))])
    error_message = "security_group_id must be a UUID."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : contains(["ingress", "egress"], r.direction)])
    error_message = "direction must be one of ingress or egress."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.ether_type == null || contains(["IPv4", "IPv6"], r.ether_type)])
    error_message = "ether_type must be one of IPv4 or IPv6 (case-sensitive, as the API expects)."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.protocol_name == null || contains(["ah", "dccp", "egp", "esp", "gre", "icmp", "igmp", "ipip", "ipv6-encap", "ipv6-frag", "ipv6-icmp", "ipv6-nonxt", "ipv6-opts", "ipv6-route", "ospf", "pgm", "rsvp", "sctp", "tcp", "udp", "udplite", "vrrp"], r.protocol_name)])
    error_message = "protocol_name must be one of ah, dccp, egp, esp, gre, icmp, igmp, ipip, ipv6-encap, ipv6-frag, ipv6-icmp, ipv6-nonxt, ipv6-opts, ipv6-route, ospf, pgm, rsvp, sctp, tcp, udp, udplite or vrrp."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.protocol_number == null || (r.protocol_number >= 0 && r.protocol_number <= 255)])
    error_message = "protocol_number must be between 0 and 255."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : !(r.protocol_name != null && r.protocol_number != null)])
    error_message = "protocol_name and protocol_number are mutually exclusive; omit both for a rule matching any protocol."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.icmp_parameters == null || (r.protocol_name != null && contains(["icmp", "ipv6-icmp"], r.protocol_name))])
    error_message = "icmp_parameters requires protocol_name set to icmp or ipv6-icmp (use protocol_name, not protocol_number, for ICMP rules)."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.port_range == null || (r.protocol_name == null || !contains(["icmp", "ipv6-icmp"], r.protocol_name))])
    error_message = "port_range cannot be combined with an ICMP protocol (protocol_name icmp or ipv6-icmp)."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.port_range == null || (r.port_range.min >= 0 && r.port_range.min <= 65535 && r.port_range.max >= 0 && r.port_range.max <= 65535 && r.port_range.min <= r.port_range.max)])
    error_message = "port_range min and max must be between 0 and 65535, and min must be less than or equal to max."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.icmp_parameters == null || (r.icmp_parameters.type >= 0 && r.icmp_parameters.type <= 255 && r.icmp_parameters.code >= 0 && r.icmp_parameters.code <= 255)])
    error_message = "icmp_parameters type and code must be between 0 and 255."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.ip_range == null || can(cidrhost(r.ip_range, 0))])
    error_message = "ip_range must be a valid CIDR in IPv4 or IPv6 notation (e.g. 10.0.0.0/8 or 2001:db8::/32)."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.remote_security_group_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.remote_security_group_id))])
    error_message = "remote_security_group_id must be a UUID."
  }

  validation {
    condition     = alltrue([for r in var.security_group_rules : r.description == null || length(r.description) <= 127])
    error_message = "description must be at most 127 characters."
  }
}
