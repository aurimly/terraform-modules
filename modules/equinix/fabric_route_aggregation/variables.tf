variable "route_aggregations" {
  description = "Map of Equinix Fabric route aggregations keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_route_aggregation. Rules and connection attachments reference entries by key."
  type = map(object({
    name        = string
    type        = string # BGP_IPv4_PREFIX_AGGREGATION, BGP_IPv6_PREFIX_AGGREGATION
    description = optional(string)
    project = object({
      project_id = string
    })
  }))

  validation {
    condition     = alltrue([for a in var.route_aggregations : contains(["BGP_IPv4_PREFIX_AGGREGATION", "BGP_IPv6_PREFIX_AGGREGATION"], a.type)])
    error_message = "type must be BGP_IPv4_PREFIX_AGGREGATION or BGP_IPv6_PREFIX_AGGREGATION (case-sensitive)."
  }

  validation {
    condition     = alltrue([for a in var.route_aggregations : length(a.project.project_id) > 0])
    error_message = "project.project_id must be a non-empty Equinix IAM project id."
  }
}

variable "rules" {
  description = "Map of route aggregation rules keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_route_aggregation_rule on the referenced aggregation. Only prefix updates in place — name and description are create-only (recreate under a new key to change them). Moving a rule to another aggregation is an honest destroy + create (the resource key includes the aggregation key)."
  type = map(object({
    aggregation_key = string # key into var.route_aggregations
    name            = string
    prefix          = string # CIDR, e.g. 192.168.0.0/24
    description     = optional(string)
  }))

  validation {
    condition     = alltrue([for r in var.rules : contains(keys(var.route_aggregations), r.aggregation_key)])
    error_message = "every rules[].aggregation_key must be a key of var.route_aggregations."
  }

  validation {
    condition     = alltrue([for r in var.rules : can(regex("^[0-9a-fA-F:.]+/\\d{1,3}$", r.prefix))])
    error_message = "prefix must be a CIDR (e.g. 192.168.0.0/24). The prefix family matching the aggregation type is enforced by the API at apply."
  }

  validation {
    condition     = length(distinct([for k, r in var.rules : "${r.aggregation_key}/${r.name}"])) == length(var.rules)
    error_message = "rule names must be unique per aggregation (two rules with the same name on one aggregation is an API conflict)."
  }
}

variable "connection_attachments" {
  description = "Map of route aggregation connection attachments keyed by an arbitrary unique identifier. Each entry attaches one existing connection (typically a fabric_connection output uuid) to the referenced aggregation."
  type = map(object({
    aggregation_key = string # key into var.route_aggregations
    connection_id   = string # Fabric connection uuid (consumer-side)
  }))

  validation {
    condition     = alltrue([for a in var.connection_attachments : contains(keys(var.route_aggregations), a.aggregation_key)])
    error_message = "every connection_attachments[].aggregation_key must be a key of var.route_aggregations."
  }

  validation {
    condition     = length(distinct([for k, a in var.connection_attachments : "${a.aggregation_key}/${a.connection_id}"])) == length(var.connection_attachments)
    error_message = "each (aggregation_key, connection_id) pair must be unique — one attachment per connection per aggregation."
  }
}
