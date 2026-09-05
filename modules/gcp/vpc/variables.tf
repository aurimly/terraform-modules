variable "networks" {
  description = "Map of VPC networks keyed by an arbitrary identifier. Each entry creates one google_compute_network."
  type = map(object({
    name                            = string
    project_id                      = optional(string)
    description                     = optional(string)
    auto_create_subnetworks         = optional(bool, false)
    routing_mode                    = optional(string, "REGIONAL")
    delete_default_routes_on_create = optional(bool, false)
    mtu                             = optional(number)
  }))

  validation {
    condition     = alltrue([for n in var.networks : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", n.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for n in var.networks : contains(["REGIONAL", "GLOBAL"], n.routing_mode)])
    error_message = "routing_mode must be one of REGIONAL or GLOBAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.mtu == null || (floor(n.mtu) == n.mtu && n.mtu >= 1300 && n.mtu <= 8896)])
    error_message = "mtu must be an integer between 1300 and 8896 bytes (provider default 1460)."
  }

  validation {
    condition     = alltrue([for n in var.networks : n.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", n.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}
