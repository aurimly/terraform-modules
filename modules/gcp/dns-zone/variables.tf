variable "zones" {
  description = "Map of Cloud DNS managed zones keyed by an arbitrary identifier. Each entry creates one google_dns_managed_zone."
  type = map(object({
    name          = string
    dns_name      = string
    project_id    = optional(string)
    description   = optional(string)
    visibility    = optional(string, "public")
    force_destroy = optional(bool, false)
    labels        = optional(map(string), {})
    dnssec_config = optional(object({
      state         = string
      non_existence = optional(string)
      default_key_specs = optional(list(object({
        algorithm  = string
        key_length = number
        key_type   = string
      })), [])
    }))
    private_visibility_config = optional(object({
      networks     = optional(list(object({ network_url = string })), [])
      gke_clusters = optional(list(object({ gke_cluster_name = string })), [])
    }))
    forwarding_config = optional(object({
      target_name_servers = list(object({
        ipv4_address    = optional(string)
        ipv6_address    = optional(string)
        forwarding_path = optional(string)
      }))
    }))
    peering_config = optional(object({
      target_network = object({ network_url = string })
    }))
    cloud_logging_config = optional(object({
      enable_logging = optional(bool, true)
    }))
  }))

  validation {
    condition     = alltrue([for z in var.zones : contains(["public", "private"], z.visibility)])
    error_message = "visibility must be one of public or private."
  }

  validation {
    condition     = alltrue([for z in var.zones : can(regex("\\.$", z.dns_name))])
    error_message = "dns_name must be fully qualified and end with a trailing dot (e.g. example.com.)."
  }

  validation {
    condition     = alltrue([for z in var.zones : can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", z.name))])
    error_message = "name must start with a lowercase letter, contain only lowercase letters, digits and hyphens, and end with a letter or digit (shape check, not a validity list). It is the zone identifier used by the API, not the DNS name."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", z.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.private_visibility_config == null || z.visibility == "private"])
    error_message = "private_visibility_config requires visibility = private."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.forwarding_config == null || z.visibility == "private"])
    error_message = "forwarding_config requires visibility = private."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.peering_config == null || z.visibility == "private"])
    error_message = "peering_config requires visibility = private."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.dnssec_config == null || z.visibility == "public"])
    error_message = "dnssec_config is only valid on public zones."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.forwarding_config == null || z.peering_config == null])
    error_message = "peering_config and forwarding_config are mutually exclusive; a zone cannot both forward and be peered."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.dnssec_config == null || contains(["on", "off", "transfer"], z.dnssec_config.state)])
    error_message = "dnssec_config.state must be one of on, off or transfer."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.dnssec_config == null || z.dnssec_config.non_existence == null || contains(["nsec", "nsec3"], z.dnssec_config.non_existence)])
    error_message = "dnssec_config.non_existence must be one of nsec or nsec3."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.dnssec_config == null || alltrue([for ks in z.dnssec_config.default_key_specs : contains(["keySigning", "zoneSigning"], ks.key_type)])])
    error_message = "dnssec_config.default_key_specs.key_type must be one of keySigning or zoneSigning."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.dnssec_config == null || alltrue([for ks in z.dnssec_config.default_key_specs : contains(["rsasha1", "rsasha256", "rsasha512", "ecdsap256sha256", "ecdsap384sha384"], ks.algorithm)])])
    error_message = "dnssec_config.default_key_specs.algorithm must be one of rsasha1, rsasha256, rsasha512, ecdsap256sha256 or ecdsap384sha384 (lowercase, per the provider)."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.dnssec_config == null || length(z.dnssec_config.default_key_specs) == 0 || alltrue([for t in ["keySigning", "zoneSigning"] : length([for ks in z.dnssec_config.default_key_specs : ks if ks.key_type == t]) == 1])])
    error_message = "dnssec_config.default_key_specs, when set, requires exactly one keySigning and one zoneSigning key spec."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.private_visibility_config == null || length(z.private_visibility_config.networks) + length(z.private_visibility_config.gke_clusters) >= 1])
    error_message = "private_visibility_config requires at least one network_url or gke_cluster_name entry."
  }

  validation {
    condition = alltrue([
      for z in var.zones : z.forwarding_config == null || alltrue([
        for ns in z.forwarding_config.target_name_servers : (ns.ipv4_address != null) != (ns.ipv6_address != null)
      ])
    ])
    error_message = "forwarding_config.target_name_servers require exactly one of ipv4_address or ipv6_address per entry."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.forwarding_config == null || alltrue([for ns in z.forwarding_config.target_name_servers : ns.forwarding_path == null || contains(["default", "private"], ns.forwarding_path)])])
    error_message = "forwarding_config.target_name_servers.forwarding_path must be one of default or private."
  }
}
