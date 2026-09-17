variable "gateways" {
  description = "Map of STACKIT VPN gateways keyed by an arbitrary identifier. Each entry creates one gateway in the given project and region."
  type = map(object({
    project_id   = string
    display_name = string
    plan_id      = string
    routing_type = string
    availability_zones = object({
      tunnel1 = string
      tunnel2 = string
    })
    region = optional(string)
    labels = optional(map(string))
    bgp = optional(object({
      local_asn                  = number
      override_advertised_routes = optional(list(string))
    }))
    network_config = optional(object({
      predefined_network_prefix = optional(string)
      routing_table_id          = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for g in var.gateways : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", g.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for g in var.gateways : can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", g.display_name))])
    error_message = "display_name must start and end with an alphanumeric character, may contain hyphens, and be 1-63 characters long."
  }

  validation {
    condition     = alltrue([for g in var.gateways : contains(["POLICY_BASED", "ROUTE_BASED", "BGP_ROUTE_BASED"], g.routing_type)])
    error_message = "routing_type must be one of POLICY_BASED, ROUTE_BASED, BGP_ROUTE_BASED."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.availability_zones.tunnel1 != "" && g.availability_zones.tunnel2 != ""])
    error_message = "availability_zones.tunnel1 and availability_zones.tunnel2 must be non-empty."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.bgp == null || g.bgp.local_asn >= 64512 && g.bgp.local_asn <= 4294967294])
    error_message = "bgp.local_asn must be between 64512 and 4294967294 (private ASN range)."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.bgp == null || g.bgp.override_advertised_routes == null || alltrue([for cidr in g.bgp.override_advertised_routes : can(cidrnetmask(cidr)) && can(regex("\\.", cidr))])])
    error_message = "bgp.override_advertised_routes entries must be valid IPv4 CIDRs."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.bgp == null || g.bgp.override_advertised_routes == null || length(g.bgp.override_advertised_routes) <= 100])
    error_message = "bgp.override_advertised_routes must have at most 100 entries."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.routing_type == "BGP_ROUTE_BASED" ? g.bgp != null : true])
    error_message = "bgp must be set when routing_type is set to BGP_ROUTE_BASED."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.network_config == null || g.network_config.predefined_network_prefix == null || (can(cidrnetmask(g.network_config.predefined_network_prefix)) && can(regex("\\.", g.network_config.predefined_network_prefix)) && tonumber(split("/", g.network_config.predefined_network_prefix)[1]) >= 28)])
    error_message = "network_config.predefined_network_prefix must be a valid IPv4 CIDR with a prefix length of /28 or larger."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.network_config == null || g.network_config.routing_table_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", g.network_config.routing_table_id))])
    error_message = "network_config.routing_table_id must be a UUID."
  }
}
