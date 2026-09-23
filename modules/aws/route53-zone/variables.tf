variable "zones" {
  description = "Map of Route 53 hosted zones keyed by an arbitrary identifier. Each entry creates one aws_route53_zone."
  type = map(object({
    name                  = string
    private               = optional(bool, false)
    comment               = optional(string)
    delegation_set_id     = optional(string)
    create_delegation_set = optional(bool, false)
    force_destroy         = optional(bool, false)
    vpc_ids               = optional(list(string), [])
    tags                  = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for z in var.zones : can(regex("^([a-z0-9-]+\\.)+[a-z]{2,}\\.?$", z.name))])
    error_message = "name must be a valid domain name (e.g. example.com)."
  }

  validation {
    condition     = alltrue([for z in var.zones : !z.create_delegation_set || z.delegation_set_id == null])
    error_message = "create_delegation_set and delegation_set_id are mutually exclusive (either reuse an existing delegation set or create a new one)."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.private || length(z.vpc_ids) == 0])
    error_message = "vpc_ids only apply to private zones."
  }

  validation {
    condition     = alltrue([for z in var.zones : !z.private || length(z.vpc_ids) > 0])
    error_message = "private zones require at least one vpc_id."
  }
}
