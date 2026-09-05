variable "routers" {
  description = "Map of Cloud Routers to create, keyed by an arbitrary identifier. Omit to reference existing routers by name or self link in the nats map."
  type = map(object({
    name        = string
    network     = string
    region      = string
    project_id  = optional(string)
    description = optional(string)
    bgp = optional(object({
      asn                = number
      advertise_mode     = optional(string, "DEFAULT")
      advertised_groups  = optional(list(string))
      keepalive_interval = optional(number)
      advertised_ip_ranges = optional(list(object({
        range       = string
        description = optional(string)
      })))
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.routers : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", r.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for r in var.routers : can(regex("^[a-z]+-[a-z]+[0-9]+$", r.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp == null || contains(["DEFAULT", "CUSTOM"], r.bgp.advertise_mode)])
    error_message = "bgp.advertise_mode must be one of DEFAULT or CUSTOM (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp == null || r.bgp.advertise_mode == "CUSTOM" || (r.bgp.advertised_groups == null && r.bgp.advertised_ip_ranges == null)])
    error_message = "bgp.advertised_groups and bgp.advertised_ip_ranges can only be set when bgp.advertise_mode is CUSTOM."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp == null || r.bgp.advertised_groups == null || alltrue([for g in r.bgp.advertised_groups : g == "ALL_SUBNETS"])])
    error_message = "bgp.advertised_groups currently only supports the value ALL_SUBNETS."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp == null || (r.bgp.asn >= 64512 && r.bgp.asn <= 65534 || r.bgp.asn >= 4200000000 && r.bgp.asn <= 4294967294)])
    error_message = "bgp.asn must be a private autonomous system number: 64512-65534 (2-byte) or 4200000000-4294967294 (4-byte) per RFC6996."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp == null || r.bgp.keepalive_interval == null || (r.bgp.keepalive_interval >= 20 && r.bgp.keepalive_interval <= 60)])
    error_message = "bgp.keepalive_interval must be between 20 and 60 seconds (provider default 20)."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "nats" {
  description = "Map of Cloud NAT gateways keyed by an arbitrary identifier. Each entry creates one google_compute_router_nat on the referenced router."
  type = map(object({
    name                               = string
    region                             = string
    router                             = string
    source_subnetwork_ip_ranges_to_nat = string
    project_id                         = optional(string)
    nat_ip_allocate_option             = optional(string, "AUTO_ONLY")
    nat_ips                            = optional(list(string))
    subnetworks = optional(list(object({
      name                     = string
      source_ip_ranges_to_nat  = list(string)
      secondary_ip_range_names = optional(list(string))
    })), [])
    log_config = optional(object({
      enable = optional(bool, true)
      filter = optional(string, "ALL")
    }))
    min_ports_per_vm                    = optional(number)
    max_ports_per_vm                    = optional(number)
    enable_dynamic_port_allocation      = optional(bool)
    enable_endpoint_independent_mapping = optional(bool)
    udp_idle_timeout_sec                = optional(number)
    icmp_idle_timeout_sec               = optional(number)
    tcp_established_idle_timeout_sec    = optional(number)
    tcp_transitory_idle_timeout_sec     = optional(number)
  }))

  validation {
    condition     = alltrue([for n in var.nats : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", n.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for n in var.nats : can(regex("^[a-z]+-[a-z]+[0-9]+$", n.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for n in var.nats : contains(["AUTO_ONLY", "MANUAL_ONLY"], n.nat_ip_allocate_option)])
    error_message = "nat_ip_allocate_option must be one of AUTO_ONLY or MANUAL_ONLY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.nat_ip_allocate_option == "MANUAL_ONLY" ? length(coalesce(n.nat_ips, [])) > 0 : n.nat_ips == null])
    error_message = "nat_ip_allocate_option MANUAL_ONLY requires nat_ips (address self links); AUTO_ONLY requires nat_ips to be unset."
  }

  validation {
    condition     = alltrue([for n in var.nats : contains(["ALL_SUBNETWORKS_ALL_IP_RANGES", "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES", "LIST_OF_SUBNETWORKS"], n.source_subnetwork_ip_ranges_to_nat)])
    error_message = "source_subnetwork_ip_ranges_to_nat must be one of ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES or LIST_OF_SUBNETWORKS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? length(n.subnetworks) > 0 : length(n.subnetworks) == 0])
    error_message = "subnetworks must be non-empty only when source_subnetwork_ip_ranges_to_nat is LIST_OF_SUBNETWORKS (and must be empty otherwise)."
  }

  validation {
    condition     = alltrue([for n in var.nats : alltrue([for s in n.subnetworks : alltrue([for i in s.source_ip_ranges_to_nat : contains(["ALL_IP_RANGES", "PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"], i)])])])
    error_message = "subnetworks.source_ip_ranges_to_nat values must be one of ALL_IP_RANGES, PRIMARY_IP_RANGE or LIST_OF_SECONDARY_IP_RANGES (case-sensitive)."
  }

  validation {
    condition     = alltrue([for n in var.nats : alltrue([for s in n.subnetworks : length(coalesce(s.secondary_ip_range_names, [])) > 0 ? contains(s.source_ip_ranges_to_nat, "LIST_OF_SECONDARY_IP_RANGES") : true])])
    error_message = "subnetworks.secondary_ip_range_names can only be set when LIST_OF_SECONDARY_IP_RANGES is among that entry's source_ip_ranges_to_nat."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.log_config == null || contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], n.log_config.filter)])
    error_message = "log_config.filter must be one of ERRORS_ONLY, TRANSLATIONS_ONLY or ALL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.min_ports_per_vm == null || (n.min_ports_per_vm >= 32 && can(regex("^10*$", format("%b", n.min_ports_per_vm))))])
    error_message = "min_ports_per_vm must be a power of two of at least 32 (provider default 64 for static port allocation, 32 for dynamic)."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.max_ports_per_vm == null || coalesce(n.enable_dynamic_port_allocation, false)])
    error_message = "max_ports_per_vm can only be set when enable_dynamic_port_allocation is true."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.max_ports_per_vm == null || n.min_ports_per_vm == null || (n.max_ports_per_vm > n.min_ports_per_vm && can(regex("^10*$", format("%b", n.max_ports_per_vm))))])
    error_message = "max_ports_per_vm must be a power of two greater than min_ports_per_vm when both are set."
  }

  validation {
    condition     = alltrue([for n in var.nats : !(coalesce(n.enable_dynamic_port_allocation, false) && coalesce(n.enable_endpoint_independent_mapping, false))])
    error_message = "enable_dynamic_port_allocation and enable_endpoint_independent_mapping cannot both be true."
  }

  validation {
    condition     = alltrue([for n in var.nats : alltrue([n.udp_idle_timeout_sec == null || n.udp_idle_timeout_sec > 0, n.icmp_idle_timeout_sec == null || n.icmp_idle_timeout_sec > 0, n.tcp_established_idle_timeout_sec == null || n.tcp_established_idle_timeout_sec > 0, n.tcp_transitory_idle_timeout_sec == null || n.tcp_transitory_idle_timeout_sec > 0])])
    error_message = "idle timeout attributes must be greater than 0 when set."
  }

  validation {
    condition     = alltrue([for n in var.nats : n.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", n.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}
