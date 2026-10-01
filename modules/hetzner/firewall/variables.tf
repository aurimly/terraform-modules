variable "firewalls" {
  description = "Map of Hetzner Cloud firewalls keyed by an arbitrary identifier. Each entry creates one firewall with its rules and resources it is applied to."
  type = map(object({
    name   = string
    labels = optional(map(string), {})
    rules = optional(list(object({
      direction       = string
      protocol        = string
      port            = optional(string)
      source_ips      = optional(list(string), [])
      destination_ips = optional(list(string), [])
      description     = optional(string)
    })), [])
    apply_to = optional(list(object({
      server         = optional(number)
      label_selector = optional(string)
    })), [])
  }))

  validation {
    condition     = alltrue([for f in var.firewalls : length(f.name) >= 1 && length(f.name) <= 128])
    error_message = "name must be 1 to 128 characters."
  }

  validation {
    condition     = length(distinct([for f in var.firewalls : f.name])) == length(var.firewalls)
    error_message = "firewall names must be unique across map keys (Hetzner requires them unique per project — duplicate names would fail together at apply time)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : length(f.rules) <= 50])
    error_message = "rules are limited to 50 entries per firewall."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : contains(["in", "out"], r.direction)])])
    error_message = "rule direction must be one of in or out."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : contains(["tcp", "udp", "icmp", "gre", "esp"], r.protocol)])])
    error_message = "rule protocol must be one of tcp, udp, icmp, gre or esp."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : r.port == null || can(regex("^(any|[0-9]+(?:-[0-9]+)?)$", r.port))])])
    error_message = "rule port must be 'any', a single port or a range of two ports separated by a dash (e.g. 80-85), when set."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : (r.protocol == "tcp" || r.protocol == "udp") ? (r.port != null && r.port != "") : true])])
    error_message = "rule port is required when protocol is tcp or udp."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : (r.protocol != "tcp" && r.protocol != "udp") ? r.port == null : true])])
    error_message = "rule port is forbidden when protocol is not tcp or udp."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : length(r.source_ips) <= 100 && length(r.destination_ips) <= 100])])
    error_message = "rule source_ips and destination_ips accept at most 100 CIDR blocks each."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : alltrue([for c in concat(r.source_ips, r.destination_ips) : can(cidrhost(c, 0)) && can(regex("/[0-9]+$", c))])])])
    error_message = "rule source_ips and destination_ips entries must be IPs or CIDRs with an explicit prefix; a single host is /32 for IPv4 and /128 for IPv6 (the module is stricter than the provider, which also accepts bare IPs)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : (r.direction != "in") || length(r.destination_ips) == 0])])
    error_message = "rule destination_ips are only meaningful when direction is out."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for r in f.rules : r.description == null || length(r.description) <= 255])])
    error_message = "rule description must be at most 255 characters."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for a in f.apply_to : (a.server != null) != (a.label_selector != null)])])
    error_message = "exactly one of server or label_selector must be set per apply_to entry."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for a in f.apply_to : a.server == null || a.server > 0])])
    error_message = "apply_to server must be a positive server ID."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for k in keys(f.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k)) && length(k) <= 63])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for v in f.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }
}
