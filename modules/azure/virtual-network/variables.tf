variable "virtual_networks" {
  description = "Map of Azure virtual networks keyed by an arbitrary identifier. Each entry creates one azurerm_virtual_network in the resource group named by resource_group_name, in the subscription configured on the provider."
  type = map(object({
    name                           = string
    resource_group_name            = string
    location                       = string
    address_space                  = list(string)
    dns_servers                    = optional(list(string), [])
    bgp_community                  = optional(string)
    edge_zone                      = optional(string)
    flow_timeout_in_minutes        = optional(number)
    private_endpoint_vnet_policies = optional(string, "Disabled")
    ddos_protection_plan_id        = optional(string)
    enable_ddos_protection_plan    = optional(bool)
    encryption_enforcement         = optional(string)
    tags                           = optional(map(string), {})
  }))

  validation {
    condition = alltrue(flatten([
      for key, v in var.virtual_networks : [
        for other_key, w in var.virtual_networks :
        key == other_key || lower(v.name) != lower(w.name) || lower(v.resource_group_name) != lower(w.resource_group_name)
      ]
    ]))
    error_message = "virtual network names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : length(v.address_space) > 0 && alltrue([
        for cidr in v.address_space : can(cidrnetmask(cidr)) || can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "address_space must be a non-empty list of valid IPv4 or IPv6 CIDRs (e.g. 10.0.0.0/16 or fd00::/8) — azurerm requires exactly one of address_space or an IPAM ip_address_pool, and IPAM pools are not exposed by this module."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : alltrue([
        for ip in v.dns_servers : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip)) && alltrue([
          for octet in split(".", ip) : tonumber(octet) <= 255
        ])
      ])
    ])
    error_message = "dns_servers entries must be IPv4 addresses, each octet within 0-255 (IPv4-only is a module choice, not an Azure restriction)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : v.bgp_community == null || can(regex("^12076:[0-9]+$", v.bgp_community))
    ])
    error_message = "bgp_community must be in \"<asn>:<community>\" format with the as-number set to 12076 (Microsoft's ASN), e.g. \"12076:50010\"."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : v.flow_timeout_in_minutes == null || (v.flow_timeout_in_minutes >= 4 && v.flow_timeout_in_minutes <= 30)
    ])
    error_message = "flow_timeout_in_minutes must be between 4 and 30 minutes."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : contains(["Disabled", "Basic"], v.private_endpoint_vnet_policies)
    ])
    error_message = "private_endpoint_vnet_policies must be \"Disabled\" or \"Basic\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : v.encryption_enforcement == null || v.encryption_enforcement == "AllowUnencrypted"
    ])
    error_message = "encryption_enforcement must be \"AllowUnencrypted\" (case-sensitive) — the only enforcement value generally available; DropUnencrypted requires the virtual network encryption feature allowlist."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : (v.ddos_protection_plan_id == null) == (v.enable_ddos_protection_plan == null)
    ])
    error_message = "ddos_protection_plan_id and enable_ddos_protection_plan must be set together (or both left unset)."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : v.ddos_protection_plan_id == null || can(regex("^/", v.ddos_protection_plan_id))
    ])
    error_message = "ddos_protection_plan_id must be a full ARM resource ID (starts with \"/\"), e.g. \"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/ddosProtectionPlans/<name>\"."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : length(trimspace(v.name)) > 0 && length(trimspace(v.resource_group_name)) > 0 && length(trimspace(v.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for v in var.virtual_networks : length(v.tags) <= 50 && alltrue([for k, val in v.tags : length(k) <= 512 && length(val) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
