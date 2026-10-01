variable "floating_ips" {
  description = "Map of Hetzner Cloud floating IPs keyed by an arbitrary identifier. Each entry creates one floating IP; exactly one of home_location (new unassigned IP) or server_id (IP created on and assigned to a server) must be set."
  type = map(object({
    type              = string
    name              = optional(string)
    home_location     = optional(string)
    server_id         = optional(number)
    description       = optional(string)
    labels            = optional(map(string), {})
    delete_protection = optional(bool)
  }))

  validation {
    condition     = alltrue([for ip in var.floating_ips : contains(["ipv4", "ipv6"], ip.type)])
    error_message = "type must be one of ipv4 or ipv6."
  }

  validation {
    condition     = alltrue([for ip in var.floating_ips : (ip.home_location != null) != (ip.server_id != null)])
    error_message = "exactly one of home_location or server_id must be set."
  }

  validation {
    condition     = alltrue([for ip in var.floating_ips : ip.server_id == null || ip.server_id > 0])
    error_message = "server_id must be a positive server ID (0 is not a valid value; a floating IP is unassigned by removing this attribute)."
  }

  validation {
    condition     = alltrue([for ip in var.floating_ips : alltrue([for k in keys(ip.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) && length(k) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for ip in var.floating_ips : alltrue([for v in ip.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
