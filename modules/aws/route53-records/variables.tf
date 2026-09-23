variable "zones" {
  description = "Map of hosted zones with their records. Keys are arbitrary identifiers; zone_id comes from the zone module."
  type = map(object({
    zone_id = string
    records = map(object({
      name    = string
      type    = string
      ttl     = optional(number)
      records = optional(list(string))
      alias = optional(object({
        name                   = string
        zone_id                = string
        evaluate_target_health = optional(bool)
      }))
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for z in var.zones : can(regex("^Z[0-9A-Z]+$", z.zone_id))])
    error_message = "zone_id must be a Route 53 hosted zone ID (starts with Z)."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : contains(["SOA", "A", "TXT", "NS", "CNAME", "MX", "NAPTR", "PTR", "SRV", "SPF", "AAAA", "CAA", "DS", "TLSA", "SSHFP", "SVCB", "HTTPS"], r.type)
      ]
    ]))
    error_message = "records.type must be a valid Route 53 record type (A, AAAA, CAA, CNAME, MX, NS, PTR, SOA, SPF, SRV, TXT, DS, TLSA, SSHFP, SVCB, HTTPS)."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : (r.alias != null) != (r.records != null && length(r.records) > 0)
      ]
    ]))
    error_message = "each record must set exactly one of records (standard record values) or alias (alias target)."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : r.alias != null || r.ttl != null
      ]
    ]))
    error_message = "standard records must set ttl (alias records must not)."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : r.alias == null || r.ttl == null
      ]
    ]))
    error_message = "alias records must not set ttl (Route 53 manages alias TTLs)."
  }

  validation {
    condition = alltrue(flatten([
      for z in var.zones : [
        for r in z.records : r.records == null || length(r.records) > 0
      ]
    ]))
    error_message = "records must contain at least one value when set."
  }
}
