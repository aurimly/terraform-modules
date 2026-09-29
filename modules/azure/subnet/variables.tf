variable "subnets" {
  description = "Map of Azure subnets keyed by an arbitrary identifier. Each entry creates one azurerm_subnet inside the named virtual network — the owning virtual network must not carry inline subnet blocks (see azure/virtual-network's Notes)."
  type = map(object({
    name                                          = string
    resource_group_name                           = string
    virtual_network_name                          = string
    address_prefixes                              = list(string)
    default_outbound_access_enabled               = optional(bool, true)
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    service_endpoint_policy_ids                   = optional(list(string), [])
    delegations = optional(map(object({
      service_delegation_name = string
      actions                 = optional(list(string), [])
    })), {})
    service_endpoints = optional(map(object({
      service            = string
      network_identifier = optional(string)
    })), {})
  }))

  validation {
    condition = alltrue(flatten([
      for key, s in var.subnets : [
        for other_key, t in var.subnets :
        key == other_key || lower(s.name) != lower(t.name) || lower(s.virtual_network_name) != lower(t.virtual_network_name) || lower(s.resource_group_name) != lower(t.resource_group_name)
      ]
    ]))
    error_message = "subnet names must be unique within their virtual network, case-insensitively — two entries sharing a name, virtual network and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : length(s.address_prefixes) > 0 && alltrue([
        for cidr in s.address_prefixes : can(cidrnetmask(cidr)) || can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "address_prefixes must be a non-empty list of valid IPv4 or IPv6 CIDRs (e.g. 10.0.1.0/24 or fd00::/8) — azurerm requires exactly one of address_prefixes or an IPAM ip_address_pool, and IPAM pools are not exposed by this module."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], s.private_endpoint_network_policies)
    ])
    error_message = "private_endpoint_network_policies must be one of Disabled, Enabled, NetworkSecurityGroupEnabled or RouteTableEnabled (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.subnets : [
        for k, e in s.service_endpoints :
        length(trimspace(e.service)) > 0 && (e.network_identifier == null || can(regex("^/", e.network_identifier)))
      ]
    ]))
    error_message = "service_endpoints entries need a non-empty service name (e.g. Microsoft.Storage) and network_identifier, when set, must be a full ARM resource ID (starts with \"/\")."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.subnets : [
        for k, d in s.delegations :
        length(trimspace(d.service_delegation_name)) > 0 && alltrue([
          for action in d.actions : length(trimspace(action)) > 0
        ])
      ]
    ]))
    error_message = "delegations entries need a non-empty service_delegation_name and non-empty action strings, e.g. service_delegation_name = \"Microsoft.ContainerInstance/containerGroups\"."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : length(trimspace(s.name)) > 0 && length(trimspace(s.resource_group_name)) > 0 && length(trimspace(s.virtual_network_name)) > 0
    ])
    error_message = "name, resource_group_name and virtual_network_name must not be empty or whitespace."
  }
}
