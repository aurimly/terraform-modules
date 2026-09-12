variable "network_areas" {
  description = "Map of STACKIT network areas keyed by an arbitrary identifier. Each entry creates one network area (SNA) at the organization level. Regional settings (transfer network, ranges, prefix bounds, default nameservers) live in the separate stackit_network_area_region resource and are out of scope."
  type = map(object({
    organization_id = string
    name            = string
    labels          = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for na in var.network_areas : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", na.organization_id))])
    error_message = "organization_id must be a STACKIT organization UUID."
  }

  validation {
    condition     = alltrue([for na in var.network_areas : length(na.name) >= 1 && length(na.name) <= 63])
    error_message = "name must be 1 to 63 characters (mirrors the provider rule; the provider applies no charset restriction on network area names)."
  }

  validation {
    condition     = alltrue([for na in var.network_areas : alltrue([for k, v in na.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
