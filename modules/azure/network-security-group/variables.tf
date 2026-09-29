variable "network_security_groups" {
  description = "Map of Azure network security groups keyed by an arbitrary identifier. Each entry creates one azurerm_network_security_group plus one azurerm_network_security_rule per entry of its security_rules map — rules are separate resources, not inline blocks."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    tags                = optional(map(string), {})
    security_rules = optional(map(object({
      name                                       = string
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      description                                = optional(string)
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
    })), {})
  }))

  validation {
    condition = alltrue([
      for group_key, group in var.network_security_groups :
      can(regex("^[^.]+$", group_key)) && alltrue([
        for rule_key, rule in group.security_rules : can(regex("^[^.]+$", rule_key))
      ])
    ])
    error_message = "map keys must not contain '.' — rule resource addresses are composed as <group-key>.<rule-key>."
  }

  validation {
    condition = alltrue(flatten([
      for key, g in var.network_security_groups : [
        for other_key, h in var.network_security_groups :
        key == other_key || lower(g.name) != lower(h.name) || lower(g.resource_group_name) != lower(h.resource_group_name)
      ]
    ]))
    error_message = "network security group names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for g in var.network_security_groups : length(trimspace(g.name)) > 0 && length(trimspace(g.resource_group_name)) > 0 && length(trimspace(g.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for g in var.network_security_groups : length(g.tags) <= 50 && alltrue([for k, v in g.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules : r.priority >= 100 && r.priority <= 4096
      ]
    ]))
    error_message = "security rule priority must be between 100 and 4096 (leave gaps between priorities to make room for future rules; lower numbers are evaluated first)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules :
        contains(["Inbound", "Outbound"], r.direction) && contains(["Allow", "Deny"], r.access) && contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], r.protocol)
      ]
    ]))
    error_message = "security rule direction must be \"Inbound\" or \"Outbound\", access must be \"Allow\" or \"Deny\", and protocol must be one of Tcp, Udp, Icmp, Esp, Ah or * (all case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules :
        ((r.source_port_range == null) != (r.source_port_ranges == null)) && ((r.destination_port_range == null) != (r.destination_port_ranges == null))
      ]
    ]))
    error_message = "each security rule must set exactly one of the singular and plural port attributes per side: source_port_range or source_port_ranges, and destination_port_range or destination_port_ranges."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules :
        length([
          for v in [
            r.source_address_prefix,
            r.source_address_prefixes == null ? null : join(",", r.source_address_prefixes),
            r.source_application_security_group_ids == null ? null : join(",", r.source_application_security_group_ids)
          ] : v if v != null
          ]) == 1 && length([
          for v in [
            r.destination_address_prefix,
            r.destination_address_prefixes == null ? null : join(",", r.destination_address_prefixes),
            r.destination_application_security_group_ids == null ? null : join(",", r.destination_application_security_group_ids)
          ] : v if v != null
        ]) == 1
      ]
    ]))
    error_message = "each security rule must have exactly one source and one destination: one of {source_, destination_}address_prefix, {source_, destination_}address_prefixes or {source_, destination_}application_security_group_ids — the provider enforces exactly-one-of across each side's trio, so prefixes and ASG ids do not compose."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules : alltrue([
          for p in concat(
            r.source_port_range == null ? [] : [r.source_port_range],
            r.source_port_ranges == null ? [] : r.source_port_ranges,
            r.destination_port_range == null ? [] : [r.destination_port_range],
            r.destination_port_ranges == null ? [] : r.destination_port_ranges
          ) :
          p == "*" || (
            can(regex("^([0-9]{1,5})(-[0-9]{1,5})?$", p)) &&
            alltrue([for part in split("-", p) : tonumber(part) <= 65535]) &&
            (length(split("-", p)) == 1 || tonumber(split("-", p)[0]) <= tonumber(split("-", p)[1]))
          )
        ])
      ]
    ]))
    error_message = "ports are strings: *, a port 0-65535, or a range <from>-<to> with from <= to and both endpoints within 0-65535 — the provider performs no bounds validation on these strings."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules :
        (r.source_address_prefix == null || length(trimspace(r.source_address_prefix)) > 0) && (r.destination_address_prefix == null || length(trimspace(r.destination_address_prefix)) > 0) && alltrue([
          for p in concat(
            r.source_address_prefixes == null ? [] : r.source_address_prefixes,
            r.destination_address_prefixes == null ? [] : r.destination_address_prefixes
          ) :
          p == "*" || can(cidrnetmask(p)) || can(cidrhost(p, 0))
        ])
      ]
    ]))
    error_message = "singular {source_, destination_}address_prefix must be a non-empty string: a service tag, a wildcard \"*\" or a CIDR; the plural {source_, destination_}address_prefixes must contain only CIDRs (IPv4 or IPv6) or \"*\" — service tags are not accepted in the plural form."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules : r.description == null || length(r.description) <= 140
      ]
    ]))
    error_message = "security rule description must be at most 140 characters."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules :
        alltrue([
          for id in concat(
            r.source_application_security_group_ids == null ? [] : r.source_application_security_group_ids,
            r.destination_application_security_group_ids == null ? [] : r.destination_application_security_group_ids
          ) : can(regex("^/", id))
        ]) && (r.source_application_security_group_ids == null || length(r.source_application_security_group_ids) <= 10) && (r.destination_application_security_group_ids == null || length(r.destination_application_security_group_ids) <= 10)
      ]
    ]))
    error_message = "application_security_group_ids entries must be full ARM resource IDs (start with \"/\") and each side's list may hold at most 10 IDs (provider limit)."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules : length(trimspace(r.name)) > 0 && !can(regex("[/\\\\?%]", r.name))
      ]
    ]))
    error_message = "security rule name must be non-empty and must not contain /, \\, ? or % (Azure rule-name charset); the name is the Azure-side identity used in import IDs and is independent of the map key."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules : [
          for other_rule_key, s in g.security_rules :
          rule_key == other_rule_key || lower(r.name) != lower(s.name)
        ]
      ]
    ]))
    error_message = "security rule names must be unique within each network security group, case-insensitively — the Azure-side rule name is the identity used in import IDs."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.network_security_groups : [
        for rule_key, r in g.security_rules : [
          for other_rule_key, s in g.security_rules :
          rule_key == other_rule_key || r.direction != s.direction || r.priority != s.priority
        ]
      ]
    ]))
    error_message = "two security rules of the same network security group must not share a priority for the same direction — Azure requires unique priorities per direction within one NSG (lower numbers are evaluated first)."
  }
}
