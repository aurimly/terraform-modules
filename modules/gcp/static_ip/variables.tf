variable "addresses" {
  description = "Map of regional and global static IP addresses keyed by an arbitrary identifier. Entries are routed to google_compute_address (regional) or google_compute_global_address (global) by purpose; see the README routing table."
  type = map(object({
    name          = string
    region        = optional(string)
    project_id    = optional(string)
    description   = optional(string)
    global_ip     = optional(bool, false)
    address       = optional(string)
    address_type  = optional(string)
    purpose       = optional(string)
    network_tier  = optional(string)
    subnetwork    = optional(string)
    network       = optional(string)
    prefix_length = optional(number)
    ip_version    = optional(string)
  }))

  validation {
    condition     = alltrue([for a in var.addresses : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", a.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.region == null || can(regex("^[a-z]+-[a-z]+[0-9]+$", a.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for a in var.addresses : (a.global_ip || (a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose))) ? a.region == null : a.region != null])
    error_message = "region is required for regional entries (EXTERNAL, INTERNAL, SHARED_LOADBALANCER_VIP, IPSEC_INTERCONNECT, GCE_ENDPOINT) and must be unset for global entries."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.address_type == null || contains(["EXTERNAL", "INTERNAL"], a.address_type)])
    error_message = "address_type must be one of EXTERNAL or INTERNAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for a in var.addresses : !a.global_ip || a.purpose == null || contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose)])
    error_message = "global_ip = true supports only purpose VPC_PEERING or PRIVATE_SERVICE_CONNECT (or no purpose at all, for a global external address); shared-VIP-style purposes are regional-only."
  }

  validation {
    condition     = alltrue([for a in var.addresses : (a.global_ip || (a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose))) ? (a.purpose == null || contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose)) : (a.purpose == null || contains(["GCE_ENDPOINT", "SHARED_LOADBALANCER_VIP", "IPSEC_INTERCONNECT"], a.purpose))])
    error_message = "purpose must fit the entry type: one of VPC_PEERING, PRIVATE_SERVICE_CONNECT or unset for global entries; one of GCE_ENDPOINT, SHARED_LOADBALANCER_VIP, IPSEC_INTERCONNECT or unset (external/regional default) for regional entries."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.network_tier == null || contains(["PREMIUM", "STANDARD"], a.network_tier)])
    error_message = "network_tier must be one of PREMIUM or STANDARD (case-sensitive)."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.network_tier == null || (a.address_type != "INTERNAL" && !(a.global_ip || (a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose))))])
    error_message = "network_tier can only be set on regional EXTERNAL addresses; it is not valid for global entries or address_type = INTERNAL."
  }

  validation {
    condition     = alltrue([for a in var.addresses : (a.global_ip || (a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose))) ? a.subnetwork == null : true])
    error_message = "subnetwork is only valid on regional entries."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.subnetwork == null || (a.address_type == "INTERNAL" && (a.purpose == null || contains(["GCE_ENDPOINT", "SHARED_LOADBALANCER_VIP"], a.purpose)))])
    error_message = "subnetwork requires address_type = INTERNAL and purpose unset (defaults to GCE_ENDPOINT) or GCE_ENDPOINT / SHARED_LOADBALANCER_VIP."
  }

  validation {
    condition     = alltrue([for a in var.addresses : (a.global_ip || (a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose))) || a.address_type != "INTERNAL" || !(a.purpose == null || a.purpose == "GCE_ENDPOINT") || a.subnetwork != null])
    error_message = "regional INTERNAL entries with purpose unset or GCE_ENDPOINT require a subnetwork."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.network == null || ((a.purpose != null && contains(["VPC_PEERING", "PRIVATE_SERVICE_CONNECT"], a.purpose)) || (!a.global_ip && a.purpose == "IPSEC_INTERCONNECT"))])
    error_message = "network is only valid on global VPC_PEERING / PRIVATE_SERVICE_CONNECT entries and regional IPSEC_INTERCONNECT entries."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.ip_version == null || contains(["IPV4", "IPV6"], a.ip_version)])
    error_message = "ip_version must be one of IPV4 or IPV6 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.purpose != "PRIVATE_SERVICE_CONNECT" || a.address_type != "INTERNAL" || a.prefix_length == null])
    error_message = "prefix_length is not valid on global INTERNAL PRIVATE_SERVICE_CONNECT entries."
  }

  validation {
    condition     = alltrue([for a in var.addresses : a.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", a.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}
