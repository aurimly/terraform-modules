variable "security_groups" {
  description = "Map of STACKIT security groups keyed by an arbitrary identifier. Each entry creates one security group plus optional security group rules."
  type = map(object({
    name        = string
    project_id  = string
    region      = optional(string)
    description = optional(string)
    stateful    = optional(bool)
    labels      = optional(map(string), {})
    rules = optional(map(object({
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
    })), {})
  }))

  validation {
    condition     = alltrue([for g in var.security_groups : g.project_id != ""])
    error_message = "project_id must be set to the STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : length(g.name) >= 1 && length(g.name) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", g.name))])
    error_message = "name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between (the provider's security group name rule; slashes are not allowed here)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : g.description == null || (length(g.description) >= 1 && length(g.description) <= 127)])
    error_message = "description must be 1 to 127 characters when set."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for k, v in g.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }

  validation {
    condition     = alltrue([for gk, g in var.security_groups : !can(regex("\\.", gk)) && alltrue([for rk in keys(g.rules) : !can(regex("\\.", rk))])])
    error_message = "map keys must not contain '.' because rule resource addresses and output keys are composed as '<group key>.<rule key>'."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : contains(["ingress", "egress"], r.direction)])])
    error_message = "rules.direction must be one of ingress or egress."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.ether_type == null || contains(["IPv4", "IPv6"], r.ether_type)])])
    error_message = "rules.ether_type must be one of IPv4 or IPv6 (case-sensitive, as the API expects)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.protocol_name == null || contains(["ah", "dccp", "egp", "esp", "gre", "icmp", "igmp", "ipip", "ipv6-encap", "ipv6-frag", "ipv6-icmp", "ipv6-nonxt", "ipv6-opts", "ipv6-route", "ospf", "pgm", "rsvp", "sctp", "tcp", "udp", "udplite", "vrrp"], r.protocol_name)])])
    error_message = "rules.protocol_name must be one of ah, dccp, egp, esp, gre, icmp, igmp, ipip, ipv6-encap, ipv6-frag, ipv6-icmp, ipv6-nonxt, ipv6-opts, ipv6-route, ospf, pgm, rsvp, sctp, tcp, udp, udplite or vrrp."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.protocol_number == null || (r.protocol_number >= 0 && r.protocol_number <= 255)])])
    error_message = "rules.protocol_number must be between 0 and 255."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : !(r.protocol_name != null && r.protocol_number != null)])])
    error_message = "rules.protocol_name and rules.protocol_number are mutually exclusive; omit both for a rule matching any protocol."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.icmp_parameters == null || (r.protocol_name != null && contains(["icmp", "ipv6-icmp"], r.protocol_name))])])
    error_message = "rules.icmp_parameters requires rules.protocol_name set to icmp or ipv6-icmp (use protocol_name, not protocol_number, for ICMP rules)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.port_range == null || (r.protocol_name == null || !contains(["icmp", "ipv6-icmp"], r.protocol_name))])])
    error_message = "rules.port_range cannot be combined with an ICMP protocol (protocol_name icmp or ipv6-icmp)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.port_range == null || (r.port_range.min >= 0 && r.port_range.min <= 65535 && r.port_range.max >= 0 && r.port_range.max <= 65535 && r.port_range.min <= r.port_range.max)])])
    error_message = "rules.port_range min and max must be between 0 and 65535, and min must be less than or equal to max."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.icmp_parameters == null || (r.icmp_parameters.type >= 0 && r.icmp_parameters.type <= 255 && r.icmp_parameters.code >= 0 && r.icmp_parameters.code <= 255)])])
    error_message = "rules.icmp_parameters type and code must be between 0 and 255."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.ip_range == null || can(cidrhost(r.ip_range, 0))])])
    error_message = "rules.ip_range must be a valid CIDR in IPv4 or IPv6 notation (e.g. 10.0.0.0/8 or 2001:db8::/32)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.remote_security_group_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.remote_security_group_id))])])
    error_message = "rules.remote_security_group_id must be a UUID."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for r in g.rules : r.description == null || length(r.description) <= 127])])
    error_message = "rules.description must be at most 127 characters."
  }
}
