variable "network_interfaces" {
  description = "Map of Azure network interfaces keyed by an arbitrary identifier. Each entry creates one azurerm_network_interface with its IP configurations as inline dynamic blocks — the configurations are part of the NIC and cannot be managed by separate resources (see Notes)."
  type = map(object({
    name                           = string
    resource_group_name            = string
    location                       = string
    dns_servers                    = optional(list(string), [])
    internal_dns_name_label        = optional(string)
    accelerated_networking_enabled = optional(bool, false)
    ip_forwarding_enabled          = optional(bool, false)
    tags                           = optional(map(string), {})
    ip_configurations = map(object({
      subnet_id                     = string
      private_ip_address_allocation = string
      private_ip_address            = optional(string)
      private_ip_address_version    = optional(string, "IPv4")
      public_ip_address_id          = optional(string)
      primary                       = optional(bool, false)
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for key, n in var.network_interfaces : [
        for other_key, m in var.network_interfaces :
        key == other_key || lower(n.name) != lower(m.name) || lower(n.resource_group_name) != lower(m.resource_group_name)
      ]
    ]))
    error_message = "network interface names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for n in var.network_interfaces : length(trimspace(n.name)) > 0 && length(trimspace(n.resource_group_name)) > 0 && length(trimspace(n.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for n in var.network_interfaces : length(n.ip_configurations) > 0
    ])
    error_message = "ip_configurations must be a non-empty map — the provider requires at least one IP configuration per network interface."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations :
        length(n.ip_configurations) < 2 || length([for o in n.ip_configurations : o if o.primary]) == 1
      ]
    ]))
    error_message = "entries with two or more ip_configurations must designate exactly one as primary = true — a single-configuration NIC does not need the flag (mirrors the provider's rule)."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations : contains(["Dynamic", "Static"], c.private_ip_address_allocation) && contains(["IPv4", "IPv6"], c.private_ip_address_version)
      ]
    ]))
    error_message = "ip_configurations.*.private_ip_address_allocation must be \"Dynamic\" or \"Static\" and private_ip_address_version must be \"IPv4\" or \"IPv6\" (all case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations : (c.private_ip_address_allocation == "Static") == (c.private_ip_address != null)
      ]
    ]))
    error_message = "ip_configurations entries with allocation Static require a private_ip_address, and a private_ip_address may only be set with allocation Static."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations :
        c.private_ip_address == null || (
          c.private_ip_address_version == "IPv4" && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", c.private_ip_address)) && alltrue([
            for octet in split(".", c.private_ip_address) : tonumber(octet) <= 255
          ]) || c.private_ip_address_version == "IPv6" && can(cidrhost("${c.private_ip_address}/128", 0))
        )
      ]
    ]))
    error_message = "ip_configurations.*.private_ip_address must be a valid IP literal matching the configuration's private_ip_address_version — IPv4 (four dotted decimal octets, 0-255) or IPv6."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        length([for k, c in n.ip_configurations : c if c.private_ip_address_version == "IPv6"]) <= 1
      ]
    ]))
    error_message = "at most one ip_configuration per network interface may use private_ip_address_version \"IPv6\" — the subnet must carry IPv6 prefixes for it."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations : can(regex("^/", c.subnet_id))
      ]
    ]))
    error_message = "ip_configurations.*.subnet_id must be a full ARM resource ID (starts with \"/\"), e.g. /subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<name> — wire it from azure/subnet's subnet_ids output."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations : c.public_ip_address_id == null || can(regex("^/", c.public_ip_address_id))
      ]
    ]))
    error_message = "ip_configurations.*.public_ip_address_id, when set, must be a full ARM resource ID (starts with \"/\") — wire it from azure/public-ip's public_ip_ids output."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for server in n.dns_servers :
        can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", server)) && alltrue([for octet in split(".", server) : tonumber(octet) <= 255])
      ]
    ]))
    error_message = "dns_servers entries must be IPv4 addresses (four dotted decimal octets, 0-255) — IPv4-only is a module choice, mirroring azure/virtual-network's dns_servers."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.network_interfaces : [
        for k, c in n.ip_configurations : length(trimspace(k)) > 0
      ]
    ]))
    error_message = "ip_configurations map keys must be non-empty — the key doubles as the IP configuration block's name (Azure enforces the name charset at apply)."
  }

  validation {
    condition = alltrue([
      for n in var.network_interfaces : length(n.tags) <= 50 && alltrue([for k, v in n.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
