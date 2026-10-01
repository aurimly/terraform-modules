variable "networks" {
  description = "Map of Hetzner Cloud networks keyed by an arbitrary identifier. Each entry creates one network. Subnets and routes are managed separately (hcloud_network_subnet / hcloud_network_route) and are not part of this module."
  type = map(object({
    name                     = string
    ip_range                 = string
    labels                   = optional(map(string), {})
    delete_protection        = optional(bool)
    expose_routes_to_vswitch = optional(bool)
  }))

  validation {
    condition     = alltrue([for n in var.networks : length(n.name) >= 1 && length(n.name) <= 255])
    error_message = "name must be 1 to 255 characters."
  }

  validation {
    condition     = length(distinct([for n in var.networks : n.name])) == length(var.networks)
    error_message = "network names must be unique across map keys (Hetzner requires them unique per project — duplicate names would fail together at apply time)."
  }

  validation {
    condition     = alltrue([for n in var.networks : can(cidrnetmask(n.ip_range))])
    error_message = "ip_range must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }

  validation {
    condition = alltrue([for n in var.networks : can(cidrnetmask(n.ip_range)) && anytrue([
      can(regex("^10\\.", n.ip_range)),
      can(regex("^172\\.(1[6-9]|2[0-9]|3[01])\\.", n.ip_range)),
      can(regex("^192\\.168\\.", n.ip_range)),
    ])])
    error_message = "ip_range must be a private RFC1918 range: 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16."
  }

  validation {
    condition     = alltrue([for n in var.networks : alltrue([for k in keys(n.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) && length(k) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for n in var.networks : alltrue([for v in n.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
