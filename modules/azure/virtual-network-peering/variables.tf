variable "virtual_network_peerings" {
  description = "Map of Azure virtual network peering directions keyed by an arbitrary identifier. Each entry creates one azurerm_virtual_network_peering from the local virtual network (named by virtual_network_name in resource_group_name) to the remote virtual network identified by remote_virtual_network_id — Azure peerings are one-directional, so working bidirectional connectivity needs one entry per side. Both networks must live in the tenant configured on the provider; the remote may be in a different resource group or subscription."
  type = map(object({
    name                                   = string
    resource_group_name                    = string
    virtual_network_name                   = string
    remote_virtual_network_id              = string
    allow_virtual_network_access           = optional(bool, true)
    allow_forwarded_traffic                = optional(bool, false)
    allow_gateway_transit                  = optional(bool, false)
    use_remote_gateways                    = optional(bool, false)
    peer_complete_virtual_networks_enabled = optional(bool, true)
    only_ipv6_peering_enabled              = optional(bool, false)
    local_subnet_names                     = optional(list(string), [])
    remote_subnet_names                    = optional(list(string), [])
    triggers                               = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for p in var.virtual_network_peerings : can(regex("^/", p.remote_virtual_network_id))
    ])
    error_message = "remote_virtual_network_id must be a full ARM resource ID starting with \"/\" — feed the azure/virtual-network module's virtual_network_ids values (the remote may be in another resource group or subscription)."
  }

  validation {
    condition = alltrue(flatten([
      for key, p in var.virtual_network_peerings : [
        for other_key, q in var.virtual_network_peerings :
        key == other_key || lower(p.resource_group_name) != lower(q.resource_group_name) || lower(p.virtual_network_name) != lower(q.virtual_network_name) || lower(p.name) != lower(q.name)
      ]
    ]))
    error_message = "peering names must be unique within their virtual network, case-insensitively — two entries sharing a name, virtual network and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for p in var.virtual_network_peerings : length(trimspace(p.name)) > 0 && length(trimspace(p.resource_group_name)) > 0 && length(trimspace(p.virtual_network_name)) > 0
    ])
    error_message = "name, resource_group_name and virtual_network_name must not be empty or whitespace; the peering lives in the local virtual network's resource group — its location is inherited and not configurable."
  }

  validation {
    condition = alltrue([
      for p in var.virtual_network_peerings : alltrue([
        for name in concat(p.local_subnet_names, p.remote_subnet_names) : length(trimspace(name)) > 0
      ])
    ])
    error_message = "local_subnet_names and remote_subnet_names entries must be non-empty subnet names."
  }

  validation {
    condition = alltrue([
      for p in var.virtual_network_peerings :
      (length(p.local_subnet_names) == 0 && length(p.remote_subnet_names) == 0) || !p.peer_complete_virtual_networks_enabled
    ])
    error_message = "subnet peering (local_subnet_names/remote_subnet_names) requires peer_complete_virtual_networks_enabled = false — Azure peers either the complete virtual network address space or selected subnets, not both."
  }

  validation {
    condition = alltrue([
      for p in var.virtual_network_peerings : alltrue([
        for k, v in p.triggers : length(trimspace(k)) > 0 && length(trimspace(v)) > 0
      ])
    ])
    error_message = "triggers keys and values must be non-empty strings."
  }
}
