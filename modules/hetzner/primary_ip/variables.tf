variable "primary_ips" {
  description = "Map of Hetzner Cloud primary IPs keyed by an arbitrary identifier. Each entry creates one primary IP; exactly one of location (new unassigned IP) or assignee_id + assignee_type (IP created assigned to a server) must be set."
  type = map(object({
    name              = string
    type              = string
    location          = optional(string)
    assignee_id       = optional(number)
    assignee_type     = optional(string)
    auto_delete       = optional(bool)
    delete_protection = optional(bool)
    labels            = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for ip in var.primary_ips : contains(["ipv4", "ipv6"], ip.type)])
    error_message = "type must be one of ipv4 or ipv6."
  }

  validation {
    condition     = alltrue([for ip in var.primary_ips : (ip.location != null) != (ip.assignee_id != null)])
    error_message = "exactly one of location or assignee_id must be set per entry (note: removing assignee_id does not unassign an already-assigned IP — see README)."
  }

  validation {
    condition     = alltrue([for ip in var.primary_ips : ip.assignee_id == null || ip.assignee_type != null])
    error_message = "assignee_type is required together with assignee_id (the provider rejects assignee_id without it)."
  }

  validation {
    condition     = alltrue([for ip in var.primary_ips : ip.assignee_type == null || contains(["server"], ip.assignee_type)])
    error_message = "assignee_type must be \"server\" (the only assignee type the API supports currently)."
  }

  validation {
    condition     = alltrue([for ip in var.primary_ips : ip.assignee_id == null || ip.assignee_id > 0])
    error_message = "assignee_id must be a positive resource ID (0 is not a valid value)."
  }

  validation {
    condition     = length(distinct([for ip in var.primary_ips : ip.name])) == length(var.primary_ips)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition     = alltrue([for ip in var.primary_ips : alltrue([for k in keys(ip.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) && length(k) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for ip in var.primary_ips : alltrue([for v in ip.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
