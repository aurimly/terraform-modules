variable "network_area_regions" {
  description = "Map of STACKIT network area regional configurations keyed by an arbitrary identifier. Each entry creates the regional IPv4 config (transfer network, ranges, prefix bounds, default nameservers) of one network area in one region."
  type = map(object({
    organization_id = string
    network_area_id = string
    region          = optional(string)
    ipv4 = object({
      transfer_network      = string
      network_ranges        = map(string)
      default_nameservers   = optional(list(string))
      default_prefix_length = optional(number)
      max_prefix_length     = optional(number)
      min_prefix_length     = optional(number)
    })
  }))

  validation {
    condition     = alltrue([for nar in var.network_area_regions : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", nar.organization_id))])
    error_message = "organization_id must be a STACKIT organization UUID."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", nar.network_area_id))])
    error_message = "network_area_id must be a network area UUID (see stackit/network_area outputs)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : can(cidrnetmask(nar.ipv4.transfer_network))])
    error_message = "ipv4.transfer_network must be a valid IPv4 CIDR (e.g. 10.1.2.0/24)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : length(nar.ipv4.network_ranges) >= 1 && length(nar.ipv4.network_ranges) <= 64])
    error_message = "ipv4.network_ranges must contain 1 to 64 entries (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : alltrue([for cidr in nar.ipv4.network_ranges : can(cidrnetmask(cidr))])])
    error_message = "ipv4.network_ranges values must be valid IPv4 CIDRs (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : length(nar.ipv4.network_ranges) == length(distinct(values(nar.ipv4.network_ranges)))])
    error_message = "ipv4.network_ranges prefixes must be unique within an entry."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : nar.ipv4.default_prefix_length == null || (nar.ipv4.default_prefix_length >= 24 && nar.ipv4.default_prefix_length <= 29)])
    error_message = "ipv4.default_prefix_length must be between 24 and 29 (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : nar.ipv4.max_prefix_length == null || (nar.ipv4.max_prefix_length >= 24 && nar.ipv4.max_prefix_length <= 29)])
    error_message = "ipv4.max_prefix_length must be between 24 and 29 (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : nar.ipv4.min_prefix_length == null || (nar.ipv4.min_prefix_length >= 8 && nar.ipv4.min_prefix_length <= 29)])
    error_message = "ipv4.min_prefix_length must be between 8 and 29 (mirrors the provider rule)."
  }

  validation {
    condition = alltrue([
      for nar in var.network_area_regions :
      (nar.ipv4.min_prefix_length == null || nar.ipv4.default_prefix_length == null || nar.ipv4.min_prefix_length <= nar.ipv4.default_prefix_length) &&
      (nar.ipv4.default_prefix_length == null || nar.ipv4.max_prefix_length == null || nar.ipv4.default_prefix_length <= nar.ipv4.max_prefix_length) &&
      (nar.ipv4.min_prefix_length == null || nar.ipv4.max_prefix_length == null || nar.ipv4.min_prefix_length <= nar.ipv4.max_prefix_length)
    ])
    error_message = "ipv4 prefix lengths must satisfy min_prefix_length <= default_prefix_length <= max_prefix_length when both sides of a comparison are set (unset values get the provider defaults 24/25/29 upstream, which this check cannot see)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : nar.ipv4.default_nameservers == null || length(nar.ipv4.default_nameservers) <= 3])
    error_message = "ipv4.default_nameservers must contain at most 3 entries (API limit)."
  }

  validation {
    condition     = alltrue([for nar in var.network_area_regions : nar.ipv4.default_nameservers == null || alltrue([for ns in nar.ipv4.default_nameservers : can(cidrhost("${ns}/32", 0)) && !can(cidrhost("${ns}/128", 0))])])
    error_message = "ipv4.default_nameservers entries must be valid IPv4 addresses."
  }
}
