variable "security_groups" {
  description = "Map of security groups keyed by an arbitrary identifier. Each entry creates one aws_security_group plus optional ingress and egress rules as separate aws_vpc_security_group_*_rule resources."
  type = map(object({
    name                   = string
    description            = string
    vpc_id                 = string
    revoke_rules_on_delete = optional(bool)
    tags                   = optional(map(string), {})
    ingress = optional(map(object({
      description                  = optional(string)
      protocol                     = optional(string, "tcp")
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
      from_port                    = optional(number, 0)
      to_port                      = optional(number, 0)
    })), {})
    egress = optional(map(object({
      description                  = optional(string)
      protocol                     = optional(string, "tcp")
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
      from_port                    = optional(number, 0)
      to_port                      = optional(number, 0)
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.security_groups) : can(regex("^[^.]+$", k))])
    error_message = "map keys must not contain '.' (rule resource addresses are composed from group and rule keys)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : length(g.name) <= 255])
    error_message = "name must be at most 255 characters (AWS tag-value limit applied to Name)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : length(g.description) <= 255])
    error_message = "description must be at most 255 characters (AWS limit)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for k in keys(g.ingress) : can(regex("^[^.]+$", k))])])
    error_message = "ingress map keys must not contain '.' (rule resource addresses are composed from group and rule keys)."
  }

  validation {
    condition     = alltrue([for g in var.security_groups : alltrue([for k in keys(g.egress) : can(regex("^[^.]+$", k))])])
    error_message = "egress map keys must not contain '.' (rule resource addresses are composed from group and rule keys)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : contains(["tcp", "udp", "icmp", "icmpv6", "-1"], r.protocol)],
        [for r in g.egress : contains(["tcp", "udp", "icmp", "icmpv6", "-1"], r.protocol)]
      )
    ]))
    error_message = "rule protocol must be one of tcp, udp, icmp, icmpv6 or -1 (case-sensitive; -1 matches all protocols)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : r.protocol != "-1" || (r.from_port == 0 && r.to_port == 0)],
        [for r in g.egress : r.protocol != "-1" || (r.from_port == 0 && r.to_port == 0)]
      )
    ]))
    error_message = "rules with protocol -1 must have from_port and to_port of 0 (AWS rejects ports on all-protocol rules)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : length(compact([r.cidr_ipv4, r.cidr_ipv6, r.prefix_list_id, r.referenced_security_group_id])) == 1],
        [for r in g.egress : length(compact([r.cidr_ipv4, r.cidr_ipv6, r.prefix_list_id, r.referenced_security_group_id])) == 1]
      )
    ]))
    error_message = "each rule must have exactly one source: one of cidr_ipv4, cidr_ipv6, prefix_list_id or referenced_security_group_id."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : r.cidr_ipv4 == null || can(cidrnetmask(r.cidr_ipv4))],
        [for r in g.egress : r.cidr_ipv4 == null || can(cidrnetmask(r.cidr_ipv4))]
      )
    ]))
    error_message = "cidr_ipv4 must be a valid IPv4 CIDR with host bits unset (e.g. 10.0.0.0/8)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : r.cidr_ipv6 == null || can(cidrhost(r.cidr_ipv6, 0))],
        [for r in g.egress : r.cidr_ipv6 == null || can(cidrhost(r.cidr_ipv6, 0))]
      )
    ]))
    error_message = "cidr_ipv6 must be a valid IPv6 CIDR (e.g. ::/0)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : r.protocol != "tcp" && r.protocol != "udp" || (r.from_port >= 0 && r.to_port >= 0 && r.from_port <= r.to_port && r.to_port <= 65535)],
        [for r in g.egress : r.protocol != "tcp" && r.protocol != "udp" || (r.from_port >= 0 && r.to_port >= 0 && r.from_port <= r.to_port && r.to_port <= 65535)]
      )
    ]))
    error_message = "tcp and udp rules must have from_port <= to_port within 0-65535."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.security_groups : concat(
        [for r in g.ingress : r.protocol != "icmp" && r.protocol != "icmpv6" || (r.from_port >= 0 && r.to_port >= 0 && r.from_port <= 255 && r.to_port <= 255)],
        [for r in g.egress : r.protocol != "icmp" && r.protocol != "icmpv6" || (r.from_port >= 0 && r.to_port >= 0 && r.from_port <= 255 && r.to_port <= 255)]
      )
    ]))
    error_message = "icmp and icmpv6 rules use from_port/to_port as ICMP type and code respectively, each within 0-255 (they are independent values; type 8 with code 0 is a valid echo-request rule)."
  }
}
