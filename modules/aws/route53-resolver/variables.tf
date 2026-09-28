variable "endpoints" {
  description = "Map of Route 53 Resolver endpoints keyed by an arbitrary identifier. Each entry creates one aws_route53_resolver_endpoint (inbound, outbound, or inbound delegation) with one IP per listed subnet. name is module-required (the API generates one when omitted). Security groups are pass-through (pair with the aws/security-group module, DNS port 53)."
  type = map(object({
    name      = string
    direction = string
    ip_addresses = list(object({
      subnet_id = string
      ip        = optional(string)
      ipv6      = optional(string)
    }))
    security_group_ids                 = set(string)
    protocols                          = optional(set(string))
    resolver_endpoint_type             = optional(string)
    rni_enhanced_metrics_enabled       = optional(bool)
    target_name_server_metrics_enabled = optional(bool)
    tags                               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.endpoints) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for e in var.endpoints : contains(["INBOUND", "OUTBOUND", "INBOUND_DELEGATION"], e.direction)])
    error_message = "direction must be INBOUND, OUTBOUND or INBOUND_DELEGATION (case-sensitive); direction is immutable — changing it replaces the endpoint and its ENIs."
  }

  validation {
    condition     = alltrue([for e in var.endpoints : length(e.ip_addresses) >= 2 && length(e.ip_addresses) <= 10])
    error_message = "ip_addresses must contain 2 to 10 entries (the API requires at least two subnets in different AZs and allows at most ten IP addresses per endpoint)."
  }

  validation {
    condition     = alltrue([for e in var.endpoints : length(e.security_group_ids) >= 1])
    error_message = "security_group_ids must contain at least one security group (the API requires it; pair with the aws/security-group module — ingress tcp/udp 53 for inbound, egress tcp/udp 53 for outbound)."
  }

  validation {
    condition     = alltrue([for e in var.endpoints : e.protocols == null || alltrue([for p in e.protocols : contains(["Do53", "DoH", "DoH-FIPS"], p)])])
    error_message = "protocols entries must be one of Do53, DoH or DoH-FIPS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for e in var.endpoints : e.resolver_endpoint_type == null || contains(["IPV4", "IPV6", "DUALSTACK"], e.resolver_endpoint_type)])
    error_message = "resolver_endpoint_type must be IPV4, IPV6 or DUALSTACK (the IP type applied to all IP addresses)."
  }
}

variable "rules" {
  description = "Map of Route 53 Resolver rules keyed by an arbitrary identifier. Each entry creates one aws_route53_resolver_rule. FORWARD rules need an outbound endpoint (endpoint_key or resolver_endpoint_id) and at least one target IP; SYSTEM and RECURSIVE rules take neither. Mostly FORWARD is what consumers need; SYSTEM and RECURSIVE are supported for completeness."
  type = map(object({
    domain_name          = string
    rule_type            = string
    resolver_endpoint_id = optional(string)
    endpoint_key         = optional(string)
    target_ips = optional(list(object({
      ip       = optional(string)
      ipv6     = optional(string)
      port     = optional(number, 53)
      protocol = optional(string)
    })))
    name = optional(string)
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.rules) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for r in var.rules : contains(["FORWARD", "SYSTEM", "RECURSIVE"], r.rule_type)])
    error_message = "rule_type must be FORWARD, SYSTEM or RECURSIVE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.rule_type != "FORWARD" || (r.resolver_endpoint_id != null) != (r.endpoint_key != null)])
    error_message = "FORWARD rules need exactly one outbound endpoint: set endpoint_key (an endpoints map key) or resolver_endpoint_id (rslvr-out-...) — not both, never neither."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.rule_type == "FORWARD" || (r.resolver_endpoint_id == null && r.endpoint_key == null)])
    error_message = "SYSTEM and RECURSIVE rules take no outbound endpoint (the API rejects resolver_endpoint_id on them); only FORWARD rules reference an endpoint."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.rule_type == "FORWARD" ? length(coalesce(r.target_ips, [])) > 0 : r.target_ips == null])
    error_message = "FORWARD rules need at least one target IP (a rule with no targets fails at apply); SYSTEM and RECURSIVE rules take no target IPs."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.rules : r.target_ips == null ? [true] : [
        for t in r.target_ips : t.protocol == null || contains(["Do53", "DoH", "DoH-FIPS"], t.protocol)
      ]
    ]))
    error_message = "target_ips.protocol must be one of Do53, DoH or DoH-FIPS (case-sensitive; default Do53) and must be supported by the outbound endpoint."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.rules : r.target_ips == null ? [true] : [
        for t in r.target_ips : (t.ip == null) != (t.ipv6 == null)
      ]
    ]))
    error_message = "each target_ips entry needs exactly one of ip (IPv4) or ipv6 (IPv6 address of the DNS target)."
  }
}

variable "associations" {
  description = "Map of Route 53 Resolver rule associations keyed by an arbitrary identifier. Each entry associates one rule (in this module by rule_key, or a shared rule by rule_id) with one VPC. System rules are auto-associated with every VPC in the region; explicit associations are for forward and recursive rules."
  type = map(object({
    rule_key = optional(string)
    rule_id  = optional(string)
    vpc_id   = string
    name     = optional(string)
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.associations) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for a in var.associations : (a.rule_key != null) != (a.rule_id != null)])
    error_message = "set exactly one of rule_key (a rules map key) or rule_id (rslvr-rr-... for rules shared from another account) — not both, never neither."
  }

  validation {
    condition     = alltrue([for a in var.associations : can(regex("^vpc-[0-9a-f]{8,17}$", a.vpc_id))])
    error_message = "vpc_id must be a VPC ID (vpc-...), typically dependency.network.outputs.vpc_ids with the aws/vpc module."
  }
}

variable "dnssec_configs" {
  description = "Map of Route 53 Resolver DNSSEC validation configs keyed by an arbitrary identifier. One config per VPC; removal stops DNSSEC validation on that VPC."
  type = map(object({
    vpc_id = string
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.dnssec_configs) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for c in var.dnssec_configs : can(regex("^vpc-[0-9a-f]{8,17}$", c.vpc_id))])
    error_message = "vpc_id must be a VPC ID (vpc-...), typically dependency.network.outputs.vpc_ids with the aws/vpc module."
  }

  validation {
    condition     = length(var.dnssec_configs) == length(distinct([for c in var.dnssec_configs : c.vpc_id]))
    error_message = "only one DNSSEC config per VPC (the API rejects a second config on the same VPC) — key DNSSEC configs by VPC."
  }
}
