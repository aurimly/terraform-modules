variable "subnets" {
  description = "Map of subnetworks keyed by an arbitrary identifier. Each entry creates one google_compute_subnetwork."
  type = map(object({
    name                     = string
    network                  = string
    region                   = string
    ip_cidr_range            = string
    project_id               = optional(string)
    description              = optional(string)
    purpose                  = optional(string)
    role                     = optional(string)
    private_ip_google_access = optional(bool)
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    flow_log = optional(object({
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
      metadata_fields      = optional(list(string))
      filter_expr          = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for s in var.subnets : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(regex("^[a-z]+-[a-z]+[0-9]+$", s.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrnetmask(s.ip_cidr_range))])
    error_message = "ip_cidr_range must be a valid IPv4 CIDR with host bits unset (e.g. 10.0.0.0/24); the provider supports IPv4 only for the primary range."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.purpose == null || contains(["PRIVATE", "REGIONAL_MANAGED_PROXY", "GLOBAL_MANAGED_PROXY", "PRIVATE_SERVICE_CONNECT", "PEER_MIGRATION", "PRIVATE_NAT"], s.purpose)])
    error_message = "purpose must be one of PRIVATE, REGIONAL_MANAGED_PROXY, GLOBAL_MANAGED_PROXY, PRIVATE_SERVICE_CONNECT, PEER_MIGRATION or PRIVATE_NAT (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.role == null || contains(["ACTIVE", "BACKUP"], s.role)])
    error_message = "role must be one of ACTIVE or BACKUP (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.role == null || (s.purpose != null && contains(["REGIONAL_MANAGED_PROXY", "GLOBAL_MANAGED_PROXY"], s.purpose))])
    error_message = "role is only used with a managed-proxy purpose (REGIONAL_MANAGED_PROXY or GLOBAL_MANAGED_PROXY); set purpose accordingly or drop role."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.flow_log == null || contains(["INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN", "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"], s.flow_log.aggregation_interval)])
    error_message = "flow_log.aggregation_interval must be one of INTERVAL_5_SEC, INTERVAL_30_SEC, INTERVAL_1_MIN, INTERVAL_5_MIN, INTERVAL_10_MIN or INTERVAL_15_MIN (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.flow_log == null || (s.flow_log.flow_sampling >= 0 && s.flow_log.flow_sampling <= 1)])
    error_message = "flow_log.flow_sampling must be between 0.0 and 1.0."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.flow_log == null || contains(["EXCLUDE_ALL_METADATA", "INCLUDE_ALL_METADATA", "CUSTOM_METADATA"], s.flow_log.metadata)])
    error_message = "flow_log.metadata must be one of EXCLUDE_ALL_METADATA, INCLUDE_ALL_METADATA or CUSTOM_METADATA (case-sensitive)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.flow_log == null || s.flow_log.metadata_fields == null || s.flow_log.metadata == "CUSTOM_METADATA"])
    error_message = "flow_log.metadata_fields can only be set when flow_log.metadata is CUSTOM_METADATA."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.flow_log == null || s.purpose == null || !contains(["REGIONAL_MANAGED_PROXY", "GLOBAL_MANAGED_PROXY"], s.purpose)])
    error_message = "flow_log is not supported on subnets whose purpose is REGIONAL_MANAGED_PROXY or GLOBAL_MANAGED_PROXY."
  }

  validation {
    condition     = alltrue([for s in var.subnets : alltrue([for r in s.secondary_ranges : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", r.range_name))])])
    error_message = "secondary_ranges.range_name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : length(distinct([for r in s.secondary_ranges : r.range_name])) == length(s.secondary_ranges)])
    error_message = "secondary_ranges.range_name must be unique within each subnet."
  }

  validation {
    condition     = alltrue([for s in var.subnets : alltrue([for r in s.secondary_ranges : can(cidrnetmask(r.ip_cidr_range))])])
    error_message = "secondary_ranges.ip_cidr_range must be a valid IPv4 CIDR with host bits unset (e.g. 10.1.0.0/24)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", s.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}
