variable "ssh_keys" {
  description = "Map of Hetzner Cloud SSH keys keyed by an arbitrary identifier. Each entry creates one SSH key. Keys are project-global and used for server authentication."
  type = map(object({
    name       = string
    public_key = string
    labels     = optional(map(string), {})
  }))

  validation {
    condition     = length(distinct([for k in var.ssh_keys : k.name])) == length(var.ssh_keys)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition     = length(distinct([for k in var.ssh_keys : k.public_key])) == length(var.ssh_keys)
    error_message = "public_key must be unique per project (the API rejects keys with the same fingerprint)."
  }

  validation {
    condition     = alltrue([for k in var.ssh_keys : alltrue([for l in keys(k.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) && length(l) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for k in var.ssh_keys : alltrue([for v in k.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
