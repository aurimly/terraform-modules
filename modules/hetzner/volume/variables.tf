variable "volumes" {
  description = "Map of Hetzner Cloud volumes keyed by an arbitrary identifier. Each entry creates one volume; exactly one of location or server_id must be set."
  type = map(object({
    name              = string
    size              = number
    location          = optional(string)
    server_id         = optional(number)
    automount         = optional(bool)
    format            = optional(string)
    labels            = optional(map(string), {})
    delete_protection = optional(bool)
  }))

  validation {
    condition     = alltrue([for v in var.volumes : (v.location != null) != (v.server_id != null)])
    error_message = "exactly one of location or server_id must be set."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.server_id == null || v.server_id > 0])
    error_message = "server_id must be a positive server ID (0 is not a valid value; detach by removing this attribute)."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.automount != true || v.server_id != null])
    error_message = "automount = true requires server_id (the volume is only mountable when attached at creation)."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.format == null || contains(["xfs", "ext4"], v.format)])
    error_message = "format must be one of xfs or ext4."
  }

  validation {
    condition     = alltrue([for v in var.volumes : v.size >= 10 && v.size <= 10240])
    error_message = "size must be between 10 and 10240 GB; resizing later only grows, never shrinks."
  }

  validation {
    condition     = alltrue([for v in var.volumes : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,62}[a-zA-Z0-9])?$", v.name))])
    error_message = "name must be 1 to 64 characters, use alphanumerics, dots, underscores and hyphens, and start and end with an alphanumeric character."
  }

  validation {
    condition     = length(distinct([for v in var.volumes : v.name])) == length(var.volumes)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition     = alltrue([for v in var.volumes : alltrue([for l in keys(v.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) && length(l) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for v in var.volumes : alltrue([for val in v.labels : val == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", val))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
