variable "servers" {
  description = "Map of Hetzner Cloud servers keyed by an arbitrary identifier. Each entry creates one server."
  type = map(object({
    name        = string
    server_type = string
    image       = string
    location    = optional(string)
    user_data   = optional(string)
    ssh_keys    = optional(list(string), [])
    keep_disk   = optional(bool)
    backups     = optional(bool)
    labels      = optional(map(string), {})
    public_net = optional(object({
      ipv4_enabled = optional(bool)
      ipv6_enabled = optional(bool)
      ipv4         = optional(number)
      ipv6         = optional(number)
    }))
    network = optional(list(object({
      network_id = optional(number)
      subnet_id  = optional(string)
      ip         = optional(string)
      alias_ips  = optional(list(string), [])
    })), [])
    firewall_ids               = optional(list(number), [])
    ignore_remote_firewall_ids = optional(bool)
    placement_group_id         = optional(number)
    delete_protection          = optional(bool)
    rebuild_protection         = optional(bool)
    shutdown_before_deletion   = optional(bool)
    iso                        = optional(string)
    rescue                     = optional(string)
  }))

  validation {
    condition     = length(distinct([for s in var.servers : s.name])) == length(var.servers)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition = alltrue([for s in var.servers :
      length(s.name) <= 253 &&
      alltrue([for part in split(".", s.name) : part != "" && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]$|^[a-zA-Z0-9]$", part))])
    ])
    error_message = "name must be a valid RFC 1123 hostname: dot-separated labels of 1 to 63 alphanumerics and inner hyphens, no leading or trailing hyphens, total length up to 253 characters."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.user_data == null || length(s.user_data) <= 32768])
    error_message = "user_data must be at most 32 KiB of cloud-init data (checked on characters, not bytes)."
  }

  validation {
    condition     = alltrue([for s in var.servers : alltrue([for key in s.ssh_keys : key != ""])])
    error_message = "ssh_keys entries must each be a non-empty SSH key name or ID."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.public_net == null || s.public_net.ipv4 == null || s.public_net.ipv4_enabled != false])
    error_message = "public_net: ipv4 must not be set when ipv4_enabled is false (assigning a primary IPv4 while disabling it is rejected on in-place updates)."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.public_net == null || s.public_net.ipv6 == null || s.public_net.ipv6_enabled != false])
    error_message = "public_net: ipv6 must not be set when ipv6_enabled is false (assigning a primary IPv6 while disabling it is rejected on in-place updates)."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.placement_group_id == null || s.placement_group_id > 0])
    error_message = "placement_group_id must be a positive placement group ID (0 is not a valid value; remove this attribute to detach)."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.public_net == null || s.public_net.ipv4 == null || s.public_net.ipv4 > 0])
    error_message = "public_net: ipv4 must be a positive primary IP ID (0 is not a valid value)."
  }

  validation {
    condition     = alltrue([for s in var.servers : s.public_net == null || s.public_net.ipv6 == null || s.public_net.ipv6 > 0])
    error_message = "public_net: ipv6 must be a positive primary IP ID (0 is not a valid value)."
  }

  validation {
    condition     = alltrue([for s in var.servers : alltrue([for id in s.firewall_ids : id > 0])])
    error_message = "firewall_ids must contain positive firewall IDs."
  }

  validation {
    condition     = alltrue(flatten([for s in var.servers : [for n in s.network : n.network_id != null || n.subnet_id != null]]))
    error_message = "network: each entry must specify either network_id or subnet_id."
  }

  validation {
    condition     = alltrue(flatten([for s in var.servers : [for n in s.network : n.network_id == null || n.network_id > 0]]))
    error_message = "network: network_id must be a positive network ID."
  }

  validation {
    condition     = alltrue(flatten([for s in var.servers : [for n in s.network : n.subnet_id == null || (can(regex("^[0-9]+-.+$", n.subnet_id)) && can(cidrnetmask(split("-", n.subnet_id)[1])))]]))
    error_message = "network: subnet_id must have the format \"<network_id>-<subnet ip range>\", e.g. \"4711-10.0.1.0/24\"."
  }

  validation {
    condition     = alltrue(flatten([for s in var.servers : [for n in s.network : n.subnet_id == null || n.network_id == null || tostring(n.network_id) == split("-", n.subnet_id)[0]]]))
    error_message = "network: network_id and the subnet_id network prefix must match when both are set."
  }

  validation {
    condition = alltrue([for s in var.servers :
      length(distinct([for n in s.network : n.network_id != null ? tostring(n.network_id) : try(split("-", n.subnet_id)[0], "unset")])) == length(s.network)
    ])
    error_message = "network: a server may only be attached to each network once."
  }

  validation {
    condition = alltrue([for s in var.servers : alltrue([
      for l in keys(s.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) && length(l) <= 63
    ])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for s in var.servers : alltrue([for v in s.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
