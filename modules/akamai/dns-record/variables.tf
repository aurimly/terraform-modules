variable "zone" {
  description = "Name of the parent zone (the import ID of an akamai/dns-zone resource). Typically wired from a dns-zone dependency output: dependency.zone.outputs.zone_names[\"key\"]."
  type        = string

  validation {
    condition     = length(var.zone) >= 1 && !can(regex("\\.$", var.zone))
    error_message = "zone must not be empty and must not have a trailing dot."
  }
}

variable "records" {
  description = "Map of records keyed by an arbitrary unique identifier. Each entry owns the full record set for its name/recordtype pair in the zone — `target` is the complete list, except for brownfield MX create which appends remote hosts omitted from the config (see the module README)."
  type = map(object({
    name       = string
    recordtype = string
    ttl        = optional(number, 3600)
    target     = optional(list(string))

    subtype                = optional(number)
    flags                  = optional(number)
    protocol               = optional(number)
    algorithm              = optional(number)
    key                    = optional(string)
    keytag                 = optional(number)
    digest_type            = optional(number)
    digest                 = optional(string)
    hardware               = optional(string)
    software               = optional(string)
    priority               = optional(number)
    order                  = optional(number)
    preference             = optional(number)
    flagsnaptr             = optional(string)
    service                = optional(string)
    regexp                 = optional(string)
    replacement            = optional(string)
    iterations             = optional(number)
    salt                   = optional(string)
    next_hashed_owner_name = optional(string)
    type_bitmaps           = optional(string)
    mailbox                = optional(string)
    txt                    = optional(string)
    type_covered           = optional(string)
    original_ttl           = optional(number)
    expiration             = optional(string)
    inception              = optional(string)
    signer                 = optional(string)
    signature              = optional(string)
    labels                 = optional(number)
    weight                 = optional(number)
    port                   = optional(number)
    fingerprint_type       = optional(number)
    fingerprint            = optional(string)
    priority_increment     = optional(number)
    name_server            = optional(string)
    email_address          = optional(string)
    refresh                = optional(number)
    retry                  = optional(number)
    expiry                 = optional(number)
    nxdomain_ttl           = optional(number)
    usage                  = optional(number)
    selector               = optional(number)
    match_type             = optional(number)
    certificate            = optional(string)
    type_value             = optional(number)
    type_mnemonic          = optional(string)
    svc_priority           = optional(number)
    svc_params             = optional(string)
    target_name            = optional(string)
  }))

  validation {
    condition     = alltrue([for r in var.records : contains(["A", "AAAA", "CAA", "CNAME", "LOC", "NS", "PTR", "SPF", "TXT", "AFSDB", "DNSKEY", "DS", "HINFO", "MX", "NAPTR", "NSEC3", "NSEC3PARAM", "RP", "RRSIG", "SRV", "SSHFP", "SOA", "AKAMAICDN", "CERT", "TLSA", "SVCB", "HTTPS"], r.recordtype)])
    error_message = "recordtype must be one of A, AAAA, CAA, CNAME, LOC, NS, PTR, SPF, TXT, AFSDB, DNSKEY, DS, HINFO, MX, NAPTR, NSEC3, NSEC3PARAM, RP, RRSIG, SRV, SSHFP, SOA, AKAMAICDN, CERT, TLSA, SVCB, HTTPS (AKAMAITLC is read-only in Terraform and not accepted)."
  }

  validation {
    condition     = alltrue([for r in var.records : length(r.name) >= 1 && length(r.name) <= 255 && !can(regex("\\.$", r.name)) && (lower(r.name) == lower(var.zone) || endswith(lower(r.name), ".${lower(var.zone)}"))])
    error_message = "name must be 1 to 255 characters, without a trailing dot, and either the zone name itself (apex) or a subdomain of it, compared ignoring case."
  }

  validation {
    condition = alltrue([for r in var.records :
      contains(["A", "AAAA", "CNAME", "LOC", "NS", "PTR", "SPF", "TXT", "AFSDB", "AKAMAICDN", "MX", "CAA", "SRV"], r.recordtype) ? r.target != null && length(r.target) >= 1 :
      contains(["CERT", "DNSKEY", "DS", "HINFO", "HTTPS", "NAPTR", "NSEC3", "NSEC3PARAM", "RP", "RRSIG", "SSHFP", "SVCB", "TLSA"], r.recordtype) ? r.target == null :
    r.recordtype != "SOA" || r.target == null])
    error_message = "target is required for A, AAAA, CNAME, LOC, NS, PTR, SPF, TXT, AFSDB, AKAMAICDN, MX, CAA and SRV; it must not be set for CERT, DNSKEY, DS, HINFO, HTTPS, NAPTR, NSEC3, NSEC3PARAM, RP, RRSIG, SSHFP, SVCB and TLSA (they are built from their scalar attributes and are single-value only); and SOA takes no target at all."
  }

  validation {
    condition     = alltrue([for r in var.records : r.recordtype != "SOA" || (r.name_server != null && r.email_address != null && r.refresh != null && r.refresh != 0 && r.retry != null && r.retry != 0 && r.expiry != null && r.expiry != 0 && r.nxdomain_ttl != null && r.nxdomain_ttl != 0)])
    error_message = "SOA records must set name_server, email_address and non-zero refresh, retry, expiry and nxdomain_ttl (serial is computed and managed by Akamai)."
  }

  validation {
    condition = alltrue([for r in var.records : r.recordtype != "SRV" || r.target == null || (
      length(distinct([for t in r.target : length(split(" ", t))])) == 1 && contains([1, 4], length(split(" ", r.target[0])))
      ) && (r.priority == null || alltrue([for t in r.target : !can(regex("^[0-9]+ ", t))])) && (
      (length(split(" ", r.target[0])) == 4 && r.priority == null && r.weight == null && r.port == null) ||
      (length(split(" ", r.target[0])) == 1 && r.port != null && r.port > 0)
    )])
    error_message = "SRV target entries must be uniformly one part (\"host\", with the priority/weight/port scalars and a non-zero port set) or uniformly four parts (\"priority weight port host\", with the priority/weight/port scalars unset). The scalars cannot be combined with four-part targets, and one-part targets require port to be set."
  }

  validation {
    condition     = alltrue([for r in var.records : r.recordtype != "MX" || r.priority_increment == null || r.priority != null])
    error_message = "priority_increment requires priority to be set."
  }

  validation {
    condition     = alltrue([for r in var.records : r.recordtype != "MX" || r.priority_increment == null || r.target == null || alltrue([for t in r.target : length(split(" ", t)) == 1])])
    error_message = "priority_increment only applies to targets without an embedded priority; use either the priority/priority_increment scalars or \"priority host\" targets, not both."
  }

  validation {
    condition     = length(distinct([for r in var.records : "${lower(r.name)}/${r.recordtype}"])) == length(var.records)
    error_message = "each name/recordtype pair must be unique ignoring case: one entry owns the full record set for its name/recordtype pair, and www.example.org and WWW.example.org identify the same record set."
  }

  validation {
    condition = alltrue([for r in var.records : (r.recordtype != "TXT" && r.recordtype != "SPF") || r.target == null || alltrue([for t in r.target :
    can(regex("^\"(?:[^\"\\\\]|\\\\.){0,255}\"( \"(?:[^\"\\\\]|\\\\.){0,255}\")*$", t))])])
    error_message = "TXT and SPF targets must be one or more fully quoted strings, each section at most 255 characters, separated by a single space, with inner quotes escaped as \\\" (e.g. \"\\\"v=spf1 -all\\\"\", or format() with \\\"%s\\\"). Unquoted values are not accepted; empty content is written as a quoted \"\". The module is deliberately stricter than the provider's own normalization, which would auto-quote unquoted values; escape non-safe-ASCII bytes as \\ddd."
  }
}
