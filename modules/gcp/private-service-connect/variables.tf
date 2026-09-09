variable "connections" {
  description = "Map of private services access (service networking) connections keyed by an arbitrary identifier. Each entry creates one google_service_networking_connection plus its allocated ranges and optional peering routes config."
  type = map(object({
    network                 = string
    service                 = optional(string, "servicenetworking.googleapis.com")
    reserved_peering_ranges = optional(list(string), [])
    deletion_policy         = optional(string)
    allocate_ranges = optional(map(object({
      name          = string
      prefix_length = number
      address       = optional(string)
      project_id    = optional(string)
      description   = optional(string)
      labels        = optional(map(string), {})
    })), {})
    routes_config = optional(object({
      import_custom_routes                = bool
      export_custom_routes                = bool
      import_subnet_routes_with_public_ip = optional(bool)
      export_subnet_routes_with_public_ip = optional(bool)
    }))
  }))

  validation {
    condition     = alltrue([for c in var.connections : length(c.network) > 0])
    error_message = "network is required (VPC name or self link)."
  }

  validation {
    condition     = alltrue([for c in var.connections : length(c.reserved_peering_ranges) + length(c.allocate_ranges) >= 1])
    error_message = "each connection needs at least one range: set allocate_ranges and/or reserved_peering_ranges (the connection resource requires non-empty reserved_peering_ranges)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for r in c.allocate_ranges : r.prefix_length >= 16 && r.prefix_length <= 24])])
    error_message = "allocate_ranges.prefix_length must be between 16 and 24 (VPC peering allocation sizes)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for r in c.allocate_ranges : r.name != null && can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", r.name))])])
    error_message = "allocate_ranges.name must follow RFC1035: lowercase letters, digits and hyphens, starting with a letter, 1 to 63 characters (global address naming rules)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for r in c.allocate_ranges : r.address == null || can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", r.address))])])
    error_message = "allocate_ranges.address must be an IPv4 address (the first address of the range)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for r in c.allocate_ranges : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])])
    error_message = "allocate_ranges.project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.deletion_policy == null || contains(["ABANDON", "REMOVE_PEERING"], c.deletion_policy)])
    error_message = "deletion_policy must be one of ABANDON or REMOVE_PEERING (case-sensitive)."
  }
}
