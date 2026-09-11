variable "managed_zone_name" {
  description = "Name of the managed zone the record sets belong to (the zone identifier, not the DNS name — use the zone_names output from gcp/dns-zone)."
  type        = string
}

variable "project_id" {
  description = "Project the managed zone lives in; defaults to the provider-level project."
  type        = string
  default     = null
}

variable "record_sets" {
  description = "Map of DNS record sets keyed by an arbitrary unique identifier (needed because records like CAA share the name '@'). Exactly one of rrdatas or routing_policy must be set per record set."
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    rrdatas = optional(list(string))
    routing_policy = optional(object({
      enable_geo_fencing = optional(bool)
      wrr = optional(list(object({
        weight  = number
        rrdatas = optional(list(string))
        health_checked_targets = optional(object({ external_endpoints = optional(list(string)), internal_load_balancers = list(object({
          ip_address         = string
          port               = string
          ip_protocol        = string
          load_balancer_type = optional(string)
          network_url        = string
          project            = string
          region             = optional(string)
        })) }))
      })))
      geo = optional(list(object({
        location = string
        rrdatas  = optional(list(string))
        health_checked_targets = optional(object({ external_endpoints = optional(list(string)), internal_load_balancers = list(object({
          ip_address         = string
          port               = string
          ip_protocol        = string
          load_balancer_type = optional(string)
          network_url        = string
          project            = string
          region             = optional(string)
        })) }))
      })))
      primary_backup = optional(object({
        primary = object({ external_endpoints = optional(list(string)), internal_load_balancers = list(object({
          ip_address         = string
          port               = string
          ip_protocol        = string
          load_balancer_type = optional(string)
          network_url        = string
          project            = string
          region             = optional(string)
        })) })
        backup_geo = list(object({
          location = string
          rrdatas  = optional(list(string))
          health_checked_targets = optional(object({ external_endpoints = optional(list(string)), internal_load_balancers = list(object({
            ip_address         = string
            port               = string
            ip_protocol        = string
            load_balancer_type = optional(string)
            network_url        = string
            project            = string
            region             = optional(string)
          })) }))
        }))
        trickle_ratio                  = optional(number)
        enable_geo_fencing_for_backups = optional(bool)
      }))
    }))
  }))

  validation {
    condition     = alltrue([for r in var.record_sets : (r.rrdatas == null) != (r.routing_policy == null)])
    error_message = "each record set must set exactly one of rrdatas or routing_policy."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : can(regex("\\.$", r.name))])
    error_message = "name must be fully qualified and end with a trailing dot (e.g. www.example.com.); the provider does not qualify relative names."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : can(regex("^[A-Z][A-Z0-9]*$", r.type))])
    error_message = "type must be an uppercase record type (e.g. A, MX, TXT, CAA); it is a shape check, not a list of valid types."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : r.ttl >= 1])
    error_message = "ttl must be at least 1 second."
  }

  validation {
    condition = alltrue([
      for r in var.record_sets : r.routing_policy == null || length([
        for p in ["wrr", "geo", "primary_backup"] : p if r.routing_policy[p] != null
      ]) == 1
    ])
    error_message = "routing_policy requires exactly one of wrr, geo or primary_backup."
  }

  validation {
    condition = alltrue([
      for r in var.record_sets : r.routing_policy == null || alltrue([
        for entry in concat(
          coalesce(try(r.routing_policy.wrr, []), []),
          coalesce(try(r.routing_policy.geo, []), []),
          coalesce(try(r.routing_policy.primary_backup.backup_geo, []), []),
        ) : anytrue([entry.rrdatas != null, entry.health_checked_targets != null])
      ])
    ])
    error_message = "each routing_policy wrr/geo entry must set at least one of rrdatas or health_checked_targets."
  }

  validation {
    condition = alltrue([
      for r in var.record_sets : r.routing_policy == null || r.routing_policy.primary_backup == null || alltrue([
        for entry in [r.routing_policy.primary_backup.primary] : anytrue([entry.internal_load_balancers != null && length(entry.internal_load_balancers) > 0, entry.external_endpoints != null && length(entry.external_endpoints) > 0])
      ])
    ])
    error_message = "routing_policy.primary_backup.primary needs at least one internal_load_balancer or external_endpoints entry."
  }
}
