variable "vpc_endpoints" {
  description = "Map of VPC endpoints keyed by an arbitrary unique identifier. Each entry creates one aws_vpc_endpoint (gateway or interface)."
  type = map(object({
    vpc_endpoint_type   = optional(string, "Interface")
    vpc_id              = string
    service_name        = string
    service_region      = optional(string)
    route_table_ids     = optional(list(string), [])
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    private_dns_enabled = optional(bool)
    ip_address_type     = optional(string)
    dns_options = optional(object({
      dns_record_ip_type                             = optional(string)
      private_dns_only_for_inbound_resolver_endpoint = optional(bool)
    }))
    subnet_configuration = optional(list(object({
      subnet_id = string
      ipv4      = optional(string)
      ipv6      = optional(string)
    })))
    auto_accept = optional(bool)
    name        = optional(string)
    policy      = optional(string)
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : contains(["Gateway", "Interface"], e.vpc_endpoint_type)])
    error_message = "vpc_endpoint_type must be one of Gateway or Interface (case-sensitive; GatewayLoadBalancer and Lattice types are out of scope)."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.vpc_endpoint_type != "Gateway" || (length(e.subnet_ids) == 0 && length(e.security_group_ids) == 0 && (e.subnet_configuration == null || length(e.subnet_configuration) == 0))])
    error_message = "subnet_ids, subnet_configuration and security_group_ids apply to Interface endpoints only (the API rejects them on Gateway)."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.vpc_endpoint_type != "Interface" || length(e.route_table_ids) == 0])
    error_message = "route_table_ids applies to Gateway endpoints only (the API rejects it on Interface)."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.vpc_endpoint_type != "Interface" || length(e.subnet_ids) > 0])
    error_message = "Interface endpoints require at least one subnet_id (interface endpoints cannot function without a subnet)."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.subnet_configuration == null || alltrue([for sc in e.subnet_configuration : contains(e.subnet_ids, sc.subnet_id)])])
    error_message = "every subnet_configuration subnet_id must have a corresponding entry in subnet_ids."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.dns_options == null || e.dns_options.private_dns_only_for_inbound_resolver_endpoint == null || e.private_dns_enabled == true])
    error_message = "dns_options.private_dns_only_for_inbound_resolver_endpoint can only be set when private_dns_enabled is true."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.ip_address_type == null || contains(["ipv4", "dualstack", "ipv6"], e.ip_address_type)])
    error_message = "ip_address_type must be one of ipv4, dualstack or ipv6 (case-sensitive)."
  }

  validation {
    condition     = alltrue([for e in var.vpc_endpoints : e.dns_options == null || e.dns_options.dns_record_ip_type == null || contains(["ipv4", "dualstack", "ipv6", "service-defined"], e.dns_options.dns_record_ip_type)])
    error_message = "dns_options.dns_record_ip_type must be one of ipv4, dualstack, ipv6 or service-defined (case-sensitive)."
  }
}
