variable "route_tables" {
  description = "Map of Azure route tables keyed by an arbitrary identifier. Each entry creates one azurerm_route_table in the resource group named by resource_group_name, in the subscription configured on the provider. Routes are separate azurerm_route resources declared inside each entry's routes map — the provider's inline route blocks conflict with azurerm_route resources and are deliberately not exposed."
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, t in var.route_tables :
      can(regex("^[^.]+$", key)) && alltrue([for route_key in keys(t.routes) : can(regex("^[^.]+$", route_key))])
    ])
    error_message = "map keys must not contain '.' — route resource addresses are composed as <table-key>.<route-key>."
  }

  validation {
    condition = alltrue(flatten([
      for key, t in var.route_tables : [
        for other_key, u in var.route_tables :
        key == other_key || lower(t.name) != lower(u.name) || lower(t.resource_group_name) != lower(u.resource_group_name)
      ]
    ]))
    error_message = "route table names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for t in var.route_tables : length(trimspace(t.name)) > 0 && length(trimspace(t.resource_group_name)) > 0 && length(trimspace(t.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : [
          for other_route_key, s in t.routes :
          route_key == other_route_key || lower(r.name) != lower(s.name)
        ]
      ]
    ]))
    error_message = "route names must be unique within each route table, case-insensitively — the Azure-side route name is the identity used in import IDs."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : length(trimspace(r.name)) > 0 && !can(regex("[/\\\\?%]", r.name))
      ]
    ]))
    error_message = "route name must be non-empty and must not contain /, \\, ? or % — Azure's naming rules are stricter than this floor (the provider enforces its charset at plan), and the name is the Azure-side identity used in import IDs, independent of the map key."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], r.next_hop_type)
      ]
    ]))
    error_message = "next_hop_type must be one of VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance or None (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : r.next_hop_in_ip_address == null || r.next_hop_type == "VirtualAppliance"
      ]
    ]))
    error_message = "next_hop_in_ip_address is only allowed on routes with next_hop_type \"VirtualAppliance\" — Azure rejects it for every other next hop type."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : r.next_hop_type != "VirtualAppliance" || r.next_hop_in_ip_address != null
      ]
    ]))
    error_message = "routes with next_hop_type \"VirtualAppliance\" must set next_hop_in_ip_address — Azure requires the appliance address on that hop type."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : r.next_hop_in_ip_address == null || !can(regex("/", r.next_hop_in_ip_address)) && length(trimspace(r.next_hop_in_ip_address)) > 0 && (can(cidrnetmask("${trimspace(r.next_hop_in_ip_address)}/32")) || can(cidrhost("${trimspace(r.next_hop_in_ip_address)}/128", 0)))
      ]
    ]))
    error_message = "next_hop_in_ip_address must be a bare IPv4 or IPv6 address without a prefix length, e.g. 10.10.1.1 or fd00::1."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.route_tables : [
        for route_key, r in t.routes : length(trimspace(r.address_prefix)) > 0 && (can(cidrhost(trimspace(r.address_prefix), 0)) || can(regex("^[A-Za-z][A-Za-z0-9._]+$", trimspace(r.address_prefix))))
      ]
    ]))
    error_message = "address_prefix must be a valid IPv4 or IPv6 CIDR (e.g. 10.1.0.0/16, fd00::/8) or an Azure service tag (e.g. ApiManagement, Storage.WestEurope) — the tag charset is validated loosely on purpose; Azure rejects unknown tag names at apply."
  }

  validation {
    condition = alltrue([
      for t in var.route_tables : length(t.tags) <= 50 && alltrue([for k, v in t.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
