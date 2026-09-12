variable "record_sets" {
  description = "Map of STACKIT DNS record sets keyed by an arbitrary identifier. Each entry creates one record set in the given zone. Multiple entries may share name/type only across different zones."
  type = map(object({
    project_id = string
    zone_id    = string
    name       = string
    type       = string
    records    = list(string)
    ttl        = optional(number)
    active     = optional(bool)
    comment    = optional(string)
  }))

  validation {
    condition     = alltrue([for r in var.record_sets : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.project_id)) && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", r.zone_id))])
    error_message = "project_id and zone_id must be UUIDs."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : length(r.name) >= 1])
    error_message = "name must be at least 1 character."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : length(r.records) >= 1 && length(distinct(r.records)) == length(r.records)])
    error_message = "records must contain at least one entry and no duplicates (provider rule)."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : r.type != "A" || alltrue([for rec in r.records : can(cidrhost("${rec}/32", 0)) && can(regex("\\.", rec)) && !can(regex(":", rec))])])
    error_message = "records of an A record set must be valid IPv4 addresses (provider rule)."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : r.type != "AAAA" || alltrue([for rec in r.records : can(cidrhost("${rec}/128", 0))])])
    error_message = "records of an AAAA record set must be valid IPv6 addresses (provider rule)."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : r.type != "CNAME" || alltrue([for rec in r.records : can(regex("\\.$", rec))])])
    error_message = "records of a CNAME record set must be fully qualified domain names ending in a dot (provider rule)."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : r.ttl == null || (r.ttl >= 60 && r.ttl <= 99999999)])
    error_message = "ttl must be between 60 and 99999999 seconds when set."
  }

  validation {
    condition     = alltrue([for r in var.record_sets : r.comment == null || length(r.comment) <= 255])
    error_message = "comment must be at most 255 characters."
  }
}
