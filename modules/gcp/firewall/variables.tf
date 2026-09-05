variable "firewalls" {
  description = "Map of firewall rules keyed by an arbitrary identifier. Each entry creates one google_compute_firewall."
  type = map(object({
    name                    = string
    network                 = string
    direction               = string
    project_id              = optional(string)
    description             = optional(string)
    priority                = optional(number, 1000)
    disabled                = optional(bool, false)
    source_ranges           = optional(list(string))
    destination_ranges      = optional(list(string))
    source_tags             = optional(list(string))
    source_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    target_service_accounts = optional(list(string))
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    log_config = optional(object({
      metadata = optional(string, "INCLUDE_ALL_METADATA")
    }))
  }))

  validation {
    condition     = alltrue([for f in var.firewalls : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", f.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : contains(["INGRESS", "EGRESS"], f.direction)])
    error_message = "direction must be INGRESS or EGRESS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.priority >= 0 && f.priority <= 65535 && floor(f.priority) == f.priority])
    error_message = "priority must be an integer between 0 and 65535 (provider default 1000); a lower value beats a higher one."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : (length(f.allow) > 0) != (length(f.deny) > 0)])
    error_message = "exactly one of allow or deny must be non-empty."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.direction == "EGRESS" || f.source_ranges != null || f.source_tags != null || f.source_service_accounts != null])
    error_message = "INGRESS rules must set at least one of source_ranges, source_tags or source_service_accounts (the provider would otherwise fall back to implicit 0.0.0.0/0)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.direction == "EGRESS" || f.destination_ranges == null])
    error_message = "destination_ranges is not a valid attribute of INGRESS rules; use source_ranges / source_tags / source_service_accounts."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.direction == "INGRESS" || (f.source_ranges == null && f.source_tags == null && f.source_service_accounts == null)])
    error_message = "EGRESS rules cannot use source_ranges, source_tags or source_service_accounts; use destination_ranges."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.direction == "INGRESS" || f.destination_ranges != null])
    error_message = "EGRESS rules must set destination_ranges explicitly (the provider would otherwise fall back to implicit 0.0.0.0/0)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : !(f.source_tags != null && f.source_service_accounts != null)])
    error_message = "source_tags and source_service_accounts are mutually exclusive."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : !(f.source_service_accounts != null && f.target_tags != null)])
    error_message = "source_service_accounts and target_tags are mutually exclusive."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : !(f.target_tags != null && f.target_service_accounts != null)])
    error_message = "target_tags and target_service_accounts are mutually exclusive."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : !(f.source_tags != null && f.target_service_accounts != null)])
    error_message = "source_tags and target_service_accounts are mutually exclusive."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.log_config == null || contains(["EXCLUDE_ALL_METADATA", "INCLUDE_ALL_METADATA"], f.log_config.metadata)])
    error_message = "log_config.metadata must be one of EXCLUDE_ALL_METADATA or INCLUDE_ALL_METADATA (case-sensitive)."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for b in concat(f.allow, f.deny) : b.ports == null || contains(["tcp", "udp", "sctp", "6", "17", "132"], lower(b.protocol))])])
    error_message = "ports can only be set for tcp, udp or sctp (case-insensitive) or their protocol numbers 6, 17, 132."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : alltrue([for b in concat(f.allow, f.deny) : b.ports == null || alltrue([for p in b.ports : can(regex("^[0-9]+(-[0-9]+)?$", p))])])])
    error_message = "ports entries must be a port number or a range like 80-443, without spaces or non-ASCII dashes."
  }

  validation {
    condition     = alltrue([for f in var.firewalls : f.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", f.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}
