variable "networks" {
  description = "Map of STACKIT networks keyed by an arbitrary identifier. Each entry creates one network in the given project and region."
  type = map(object({
    name               = string
    project_id         = string
    region             = optional(string)
    routed             = optional(bool)
    dhcp               = optional(bool)
    labels             = optional(map(string), {})
    ipv4_prefix        = optional(string)
    ipv4_prefix_length = optional(number)
    ipv4_gateway       = optional(string)
    no_ipv4_gateway    = optional(bool)
    ipv4_nameservers   = optional(list(string))
    ipv6_prefix        = optional(string)
    ipv6_prefix_length = optional(number)
    ipv6_gateway       = optional(string)
    no_ipv6_gateway    = optional(bool)
    ipv6_nameservers   = optional(list(string))
  }))

  validation {
    condition     = alltrue([for n in var.networks : n.project_id != ""])
    error_message = "project_id must be set to the STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for n in var.networks : length(n.name) >= 1 && length(n.name) <= 63 && can(regex("^[A-Za-z0-9]+([ /._-]*[A-Za-z0-9]+)*$", n.name))])
    error_message = "name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, spaces, slashes, dots, underscores and hyphens in between (STACKIT GenericName rule with the provider's 63-character cap)."
  }

  validation {
    condition     = alltrue([for n in var.networks : alltrue([for k, v in n.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }

  validation {
    condition     = alltrue([for n in var.networks : !(n.ipv4_prefix != null && n.ipv4_prefix_length != null)])
    error_message = "ipv4_prefix and ipv4_prefix_length are mutually exclusive."
  }

  validation {
    condition     = alltrue([for n in var.networks : !(n.ipv6_prefix != null && n.ipv6_prefix_length != null)])
    error_message = "ipv6_prefix and ipv6_prefix_length are mutually exclusive."
  }

  validation {
    condition     = alltrue([for n in var.networks : !(n.no_ipv4_gateway == true && n.ipv4_gateway != null)])
    error_message = "no_ipv4_gateway and ipv4_gateway are mutually exclusive."
  }

  validation {
    condition     = alltrue([for n in var.networks : !(n.no_ipv6_gateway == true && n.ipv6_gateway != null)])
    error_message = "no_ipv6_gateway and ipv6_gateway are mutually exclusive."
  }

  validation {
    condition     = alltrue([for n in var.networks : !(n.ipv4_prefix_length != null && n.ipv4_gateway != null)])
    error_message = "ipv4_prefix_length and ipv4_gateway are mutually exclusive (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for n in var.networks : !(n.ipv6_prefix_length != null && n.ipv6_gateway != null)])
    error_message = "ipv6_prefix_length and ipv6_gateway are mutually exclusive (mirrors the provider rule)."
  }

  validation {
    condition = alltrue([
      for n in var.networks : n.ipv4_prefix != null || n.ipv4_prefix_length != null ||
      (n.ipv4_prefix == null && n.ipv4_prefix_length == null && n.ipv4_gateway == null && n.no_ipv4_gateway == null && n.ipv4_nameservers == null)
    ])
    error_message = "when any IPv4 attribute (ipv4_prefix, ipv4_prefix_length, ipv4_gateway, no_ipv4_gateway, ipv4_nameservers) is set, either ipv4_prefix or ipv4_prefix_length must be provided."
  }

  validation {
    condition = alltrue([
      for n in var.networks : n.ipv6_prefix != null || n.ipv6_prefix_length != null ||
      (n.ipv6_prefix == null && n.ipv6_prefix_length == null && n.ipv6_gateway == null && n.no_ipv6_gateway == null && n.ipv6_nameservers == null)
    ])
    error_message = "when any IPv6 attribute (ipv6_prefix, ipv6_prefix_length, ipv6_gateway, no_ipv6_gateway, ipv6_nameservers) is set, either ipv6_prefix or ipv6_prefix_length must be provided."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv4_prefix_length == null || (n.ipv4_prefix_length >= 8 && n.ipv4_prefix_length <= 29)])
    error_message = "ipv4_prefix_length must be between 8 and 29 (API rule)."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv6_prefix_length == null || (n.ipv6_prefix_length >= 56 && n.ipv6_prefix_length <= 128)])
    error_message = "ipv6_prefix_length must be between 56 and 128 (API rule)."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv4_prefix == null || can(cidrnetmask(n.ipv4_prefix))])
    error_message = "ipv4_prefix must be a valid IPv4 CIDR (e.g. 10.1.0.0/24)."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv6_prefix == null || (can(cidrhost(n.ipv6_prefix, 0)) && !can(cidrnetmask(n.ipv6_prefix)))])
    error_message = "ipv6_prefix must be a valid IPv6 CIDR (e.g. 2001:db8::/64)."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv4_gateway == null || (can(cidrhost("${n.ipv4_gateway}/32", 0)) && !can(cidrhost("${n.ipv4_gateway}/128", 0)))])
    error_message = "ipv4_gateway must be a valid IPv4 address."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv6_gateway == null || can(cidrhost("${n.ipv6_gateway}/128", 0))])
    error_message = "ipv6_gateway must be a valid IPv6 address."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv4_nameservers == null || length(n.ipv4_nameservers) <= 3])
    error_message = "ipv4_nameservers must contain at most 3 entries."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv6_nameservers == null || length(n.ipv6_nameservers) <= 3])
    error_message = "ipv6_nameservers must contain at most 3 entries."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv4_nameservers == null || alltrue([for ns in n.ipv4_nameservers : can(cidrhost("${ns}/32", 0)) && !can(cidrhost("${ns}/128", 0))])])
    error_message = "ipv4_nameservers entries must be valid IPv4 addresses."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.ipv6_nameservers == null || alltrue([for ns in n.ipv6_nameservers : can(cidrhost("${ns}/128", 0))])])
    error_message = "ipv6_nameservers entries must be valid IPv6 addresses."
  }
}
