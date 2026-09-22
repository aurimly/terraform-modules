variable "vpcs" {
  description = "Map of VPCs keyed by an arbitrary identifier. Each entry creates one aws_vpc."
  type = map(object({
    name                                 = string
    cidr_block                           = optional(string)
    instance_tenancy                     = optional(string, "default")
    enable_dns_support                   = optional(bool, true)
    enable_dns_hostnames                 = optional(bool, false)
    enable_network_address_usage_metrics = optional(bool)
    ipv4_ipam_pool_id                    = optional(string)
    ipv4_netmask_length                  = optional(number)
    assign_generated_ipv6_cidr_block     = optional(bool, false)
    tags                                 = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.vpcs : length(v.name) <= 255])
    error_message = "name must be at most 255 characters (AWS tag-value limit applied to Name)."
  }

  validation {
    condition     = alltrue([for v in var.vpcs : v.cidr_block == null || can(cidrnetmask(v.cidr_block))])
    error_message = "cidr_block must be a valid IPv4 CIDR with host bits unset (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = alltrue([for v in var.vpcs : contains(["default", "dedicated", "host"], v.instance_tenancy)])
    error_message = "instance_tenancy must be one of default, dedicated or host (case-sensitive)."
  }

  validation {
    condition     = alltrue([for v in var.vpcs : (v.ipv4_ipam_pool_id == null) == (v.ipv4_netmask_length == null)])
    error_message = "ipv4_netmask_length can only be set together with ipv4_ipam_pool_id."
  }

  validation {
    condition     = alltrue([for v in var.vpcs : v.ipv4_ipam_pool_id == null || v.cidr_block == null])
    error_message = "ipv4_ipam_pool_id cannot be combined with cidr_block; set exactly one of the two (AWS rejects both)."
  }

  validation {
    condition     = alltrue([for v in var.vpcs : v.cidr_block != null || v.ipv4_ipam_pool_id != null])
    error_message = "set exactly one of cidr_block or ipv4_ipam_pool_id (AWS requires one)."
  }
}
