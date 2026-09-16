variable "routes" {
  description = "Map of STACKIT network area routes (SNA) keyed by an arbitrary identifier. Each entry creates one static route inside one network area in one region."
  type = map(object({
    organization_id = string
    network_area_id = string
    region          = optional(string)
    destination = object({
      type  = string
      value = string
    })
    next_hop = object({
      type  = string
      value = optional(string)
    })
    labels = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for r in var.routes : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.organization_id))])
    error_message = "organization_id must be a STACKIT organization UUID."
  }

  validation {
    condition     = alltrue([for r in var.routes : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.network_area_id))])
    error_message = "network_area_id must be a network area UUID (see stackit/network_area outputs)."
  }

  validation {
    condition     = alltrue([for r in var.routes : contains(["cidrv4"], r.destination.type)])
    error_message = "destination.type must be \"cidrv4\" (the STACKIT API supports only cidrv4 destinations currently)."
  }

  validation {
    condition     = alltrue([for r in var.routes : can(cidrnetmask(r.destination.value))])
    error_message = "destination.value must be a valid IPv4 CIDR (e.g. 10.0.0.0/8)."
  }

  validation {
    condition     = alltrue([for r in var.routes : contains(["blackhole", "internet", "ipv4"], r.next_hop.type)])
    error_message = "next_hop.type must be one of blackhole, internet or ipv4 (the STACKIT API supports only these next hop types currently)."
  }

  validation {
    condition     = alltrue([for r in var.routes : contains(["blackhole", "internet"], r.next_hop.type) == (r.next_hop.value == null)])
    error_message = "next_hop.value must be set for ipv4 next hops and unset for blackhole and internet next hops."
  }

  validation {
    condition     = alltrue([for r in var.routes : r.next_hop.type != "ipv4" || can(cidrhost("${r.next_hop.value}/32", 0))])
    error_message = "next_hop.value must be a valid IPv4 address for ipv4 next hops."
  }

  validation {
    condition     = alltrue([for r in var.routes : alltrue([for k, v in r.labels : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", k)) && !can(regex("^stackit-", k)) && can(regex("^$|^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])])
    error_message = "labels keys must be 1 to 63 characters of letters, digits, dots, underscores or hyphens, starting and ending with a letter or digit, and must not use the reserved \"stackit-\" prefix; values follow the same shape or may be empty (IaaS label rule)."
  }
}
