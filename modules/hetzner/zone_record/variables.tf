variable "zone" {
  description = "Name or ID of the parent zone (as accepted by hcloud_zone_record.zone). Typically wired from a hetzner/zone dependency output: dependency.zone.outputs.zones[\"key\"].id."
  type        = string

  validation {
    condition     = length(var.zone) >= 1
    error_message = "zone must not be empty."
  }
}

variable "records" {
  description = "Map of records keyed by an arbitrary identifier. Each entry adds one record value to the RRSet `name`/`type` in the zone (the RRSet is auto-created if absent)."
  type = map(object({
    name    = string
    type    = string
    value   = string
    comment = optional(string)
  }))

  validation {
    condition     = alltrue([for r in var.records : contains(["A", "AAAA", "CAA", "CNAME", "DS", "HINFO", "HTTPS", "MX", "NS", "PTR", "RP", "SRV", "SVCB", "TLSA", "TXT"], r.type)])
    error_message = "type must be one of A, AAAA, CAA, CNAME, DS, HINFO, HTTPS, MX, NS, PTR, RP, SRV, SVCB, TLSA, TXT (SOA is managed by the API together with the zone)."
  }

  validation {
    condition     = alltrue([for r in var.records : length(r.name) >= 1 && length(r.name) <= 255 && r.name == lower(r.name) && !can(regex("\\.$", r.name))])
    error_message = "name must be 1 to 255 characters, lowercase, and without a trailing dot. For the zone apex use @ (for IDN names transcribe to Punycode, e.g. with the provider::hcloud::idna function)."
  }

  validation {
    condition     = length(distinct([for r in var.records : "${r.name}/${r.type}/${r.value}"])) == length(var.records)
    error_message = "record values must be distinct within each RRSet: no two entries may share the same name, type and value."
  }

  validation {
    condition     = alltrue([for r in var.records : r.type != "TXT" || can(regex("^\"(?:[^\"\\\\]|\\\\.){1,255}\"( \"(?:[^\"\\\\]|\\\\.){1,255}\")*$", r.value))])
    error_message = "TXT values must be one or more quoted strings of at most 255 characters each, with inner quotes escaped as \\\" — the exact format produced by the provider::hcloud::txt_record function."
  }
}
