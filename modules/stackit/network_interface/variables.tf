variable "network_interfaces" {
  description = "Map of STACKIT network interfaces keyed by an arbitrary identifier. Each entry creates one network interface in the given network."
  type = map(object({
    project_id         = string
    network_id         = string
    region             = optional(string)
    name               = optional(string)
    ipv4               = optional(string)
    allowed_addresses  = optional(list(string))
    security           = optional(bool)
    security_group_ids = optional(list(string))
    labels             = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for ni in var.network_interfaces : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", ni.project_id))])
    error_message = "project_id must be a STACKIT project UUID."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", ni.network_id))])
    error_message = "network_id must be a network UUID."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : ni.name == null || (length(ni.name) >= 1 && length(ni.name) <= 63 && can(regex("^[A-Za-z0-9]+((-|_|\\s|\\.)[A-Za-z0-9]+)*$", ni.name)))])
    error_message = "name must be 1 to 63 characters, start and end with a letter or digit, and contain only letters, digits, hyphens, underscores, dots and whitespace in between (mirrors the provider rule)."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : ni.ipv4 == null || (can(cidrhost("${ni.ipv4}/32", 0)) && !can(cidrhost("${ni.ipv4}/128", 0)))])
    error_message = "ipv4 must be a valid IPv4 address (changing it replaces the interface with a new MAC address)."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : ni.allowed_addresses == null || alltrue([for cidr in ni.allowed_addresses : can(cidrnetmask(cidr)) || (can(cidrhost(cidr, 0)) && can(regex(":", cidr)))])])
    error_message = "allowed_addresses entries must be valid CIDRs in IPv4 or IPv6 notation."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : ni.security_group_ids == null || alltrue([for sg in ni.security_group_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", sg))])])
    error_message = "security_group_ids entries must be security group UUIDs."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : ni.security != false || ni.security_group_ids == null || length(ni.security_group_ids) == 0])
    error_message = "security_group_ids must be empty when security is set to false (the provider errors otherwise)."
  }

  validation {
    condition     = alltrue([for ni in var.network_interfaces : alltrue([for k, v in ni.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
