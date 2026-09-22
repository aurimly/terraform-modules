variable "nat_gateways" {
  description = "Map of NAT gateways keyed by an arbitrary identifier, conventionally one entry per availability zone. Each entry creates one aws_nat_gateway and, unless allocation_id is given, one aws_eip."
  type = map(object({
    name                           = string
    subnet_id                      = string
    connectivity_type              = optional(string, "public")
    allocation_id                  = optional(string)
    private_ip                     = optional(string)
    secondary_allocation_ids       = optional(list(string))
    secondary_private_ip_addresses = optional(list(string))
    tags                           = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for n in var.nat_gateways : length(n.name) <= 255])
    error_message = "name must be at most 255 characters (AWS tag-value limit applied to Name)."
  }

  validation {
    condition     = alltrue([for n in var.nat_gateways : contains(["public", "private"], n.connectivity_type)])
    error_message = "connectivity_type must be one of public or private (case-sensitive)."
  }

  validation {
    condition     = alltrue([for n in var.nat_gateways : n.allocation_id == null || n.connectivity_type == "public"])
    error_message = "allocation_id can only be set when connectivity_type is public; a private NAT gateway takes no elastic IP."
  }
}
