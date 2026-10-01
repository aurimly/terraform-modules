variable "nat_gateways" {
  description = "Map of Azure NAT gateways keyed by an arbitrary identifier. Each entry creates one azurerm_nat_gateway plus its public IP and public IP prefix associations. Entries may have no IP or prefix attached at all — the gateway resource accepts that, but without either it provides no outbound connectivity (see Notes)."
  type = map(object({
    name                    = string
    resource_group_name     = string
    location                = string
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string), [])
    public_ip_address_ids   = optional(list(string), [])
    public_ip_prefix_ids    = optional(list(string), [])
    tags                    = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key in keys(var.nat_gateways) : !can(regex("\\.", key))
    ])
    error_message = "nat_gateways map keys must not contain \".\" — keys are composed into association identifiers of the form \"<gateway_key>.pip<index>\" and a dot would make outputs ambiguous and flattened keys collision-prone."
  }

  validation {
    condition = alltrue([
      for gateway in var.nat_gateways : length(trimspace(gateway.name)) > 0 && length(trimspace(gateway.resource_group_name)) > 0 && length(trimspace(gateway.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace."
  }

  validation {
    condition = alltrue([
      for gateway in var.nat_gateways : contains(["Standard", "StandardV2"], gateway.sku_name)
    ])
    error_message = "sku_name must be one of Standard or StandardV2 (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for gateway in var.nat_gateways : gateway.sku_name != "StandardV2" || length(gateway.zones) == 0
    ])
    error_message = "zones must be omitted when sku_name is StandardV2 — StandardV2 NAT gateways are zone-redundant by default and Azure deploys across all available zones."
  }

  validation {
    condition = alltrue([
      for gateway in var.nat_gateways : gateway.sku_name != "Standard" || length(gateway.zones) <= 1
    ])
    error_message = "a Standard NAT gateway accepts at most one availability zone (single element from [\"1\", \"2\", \"3\"]) or an empty zones list for a no-zone deployment."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.nat_gateways : [
        for zone in gateway.zones : contains(["1", "2", "3"], zone)
      ]
    ]))
    error_message = "zones entries must be \"1\", \"2\" or \"3\" — availability zone numbers."
  }

  validation {
    condition = alltrue([
      for gateway in var.nat_gateways : gateway.idle_timeout_in_minutes >= 4 && gateway.idle_timeout_in_minutes <= 120
    ])
    error_message = "idle_timeout_in_minutes must be between 4 and 120 inclusive (Azure-enforced range)."
  }

  validation {
    condition = alltrue(flatten([
      for gateway in var.nat_gateways : [
        for id in concat(gateway.public_ip_address_ids, gateway.public_ip_prefix_ids) : can(regex("^/", id))
      ]
    ]))
    error_message = "public_ip_address_ids and public_ip_prefix_ids entries must be full ARM resource IDs (start with \"/\") — typically the public_ip_ids output of the azure/public-ip module."
  }

  validation {
    condition = alltrue([
      for gateway in var.nat_gateways : length(gateway.tags) <= 50 && alltrue([for k, v in gateway.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
