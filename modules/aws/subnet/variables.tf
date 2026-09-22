variable "subnets" {
  description = "Map of subnets keyed by an arbitrary identifier. Each entry creates one aws_subnet."
  type = map(object({
    name                                = string
    vpc_id                              = string
    cidr_block                          = string
    availability_zone                   = optional(string)
    availability_zone_id                = optional(string)
    map_public_ip_on_launch             = optional(bool, false)
    private_dns_hostname_type_on_launch = optional(string)
    ipv6_cidr_block                     = optional(string)
    assign_ipv6_address_on_creation     = optional(bool, false)
    tags                                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.subnets : length(s.name) <= 255])
    error_message = "name must be at most 255 characters (AWS tag-value limit applied to Name)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrnetmask(s.cidr_block))])
    error_message = "cidr_block must be a valid IPv4 CIDR with host bits unset (e.g. 10.0.1.0/24)."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.availability_zone == null || s.availability_zone_id == null])
    error_message = "availability_zone and availability_zone_id are mutually exclusive; set exactly one (or neither to let AWS pick)."
  }
}
