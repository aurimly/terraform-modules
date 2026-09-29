variable "public_ips" {
  description = "Map of Azure public IP addresses keyed by an arbitrary identifier. Each entry creates one azurerm_public_ip in the named resource group, in the subscription configured on the provider."
  type = map(object({
    name                    = string
    resource_group_name     = string
    location                = string
    allocation_method       = string
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    ip_version              = optional(string, "IPv4")
    idle_timeout_in_minutes = optional(number)
    domain_name_label       = optional(string)
    availability_zone       = optional(string)
    ddos_protection_mode    = optional(string, "VirtualNetworkInherited")
    ddos_protection_plan_id = optional(string)
    tags                    = optional(map(string), {})
  }))

  validation {
    condition = alltrue(flatten([
      for key, p in var.public_ips : [
        for other_key, q in var.public_ips :
        key == other_key || lower(p.name) != lower(q.name) || lower(p.resource_group_name) != lower(q.resource_group_name)
      ]
    ]))
    error_message = "public IP names must be unique within their resource group, case-insensitively — two entries sharing a name and resource group conflict at apply."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : length(trimspace(p.name)) > 0 && length(trimspace(p.resource_group_name)) > 0 && length(trimspace(p.location)) > 0
    ])
    error_message = "name, resource_group_name and location must not be empty or whitespace; use an Azure region name for location — the provider normalizes display names, e.g. \"West Europe\" is accepted and stored as \"westeurope\"."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : contains(["Static", "Dynamic"], p.allocation_method)
    ])
    error_message = "allocation_method must be \"Static\" or \"Dynamic\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : contains(["Basic", "Standard", "StandardV2"], p.sku) && contains(["Regional", "Global"], p.sku_tier)
    ])
    error_message = "sku must be one of \"Basic\", \"Standard\" or \"StandardV2\" and sku_tier must be \"Regional\" or \"Global\" (all case-sensitive)."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : p.sku_tier != "Global" || p.sku == "Standard"
    ])
    error_message = "sku_tier \"Global\" requires sku \"Standard\" specifically — Global-scope addresses front cross-region load balancers and Azure rejects the Global tier with Basic or StandardV2."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : !contains(["Standard", "StandardV2"], p.sku) || p.allocation_method == "Static"
    ])
    error_message = "sku Standard or StandardV2 requires allocation_method \"Static\" — Dynamic allocation is Basic-SKU only, and the creation of new Basic SKU public IPs is blocked by the provider."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : contains(["IPv4", "IPv6"], p.ip_version)
    ])
    error_message = "ip_version must be \"IPv4\" or \"IPv6\" (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : p.idle_timeout_in_minutes == null || (p.idle_timeout_in_minutes >= 4 && p.idle_timeout_in_minutes <= 30)
    ])
    error_message = "idle_timeout_in_minutes must be between 4 and 30 minutes (the provider defaults to 4 when unset)."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : p.domain_name_label == null || length(trimspace(p.domain_name_label)) > 0
    ])
    error_message = "domain_name_label, when set, must not be empty — the provider validates the label charset at plan time (lowercase alphanumeric and hyphens, must start with a letter, end with an alphanumeric, at most 63 characters)."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : p.availability_zone == null || contains(["1", "2", "3"], p.availability_zone)
    ])
    error_message = "availability_zone must be \"1\", \"2\" or \"3\" (case-sensitive), or left unset for no zone pinning."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : contains(["Disabled", "Enabled", "VirtualNetworkInherited"], p.ddos_protection_mode)
    ])
    error_message = "ddos_protection_mode must be one of Disabled, Enabled or VirtualNetworkInherited (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : (p.ddos_protection_plan_id == null || can(regex("^/", p.ddos_protection_plan_id))) && (p.ddos_protection_plan_id == null || p.ddos_protection_mode == "Enabled")
    ])
    error_message = "ddos_protection_plan_id, when set, must be a full ARM resource ID (starts with \"/\") and ddos_protection_mode must be \"Enabled\" — the plan ID can only be attached to an IP whose DDoS protection mode is Enabled."
  }

  validation {
    condition = alltrue([
      for p in var.public_ips : length(p.tags) <= 50 && alltrue([for k, v in p.tags : length(k) <= 512 && length(v) <= 256])
    ])
    error_message = "tags are limited to 50 entries per resource, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
