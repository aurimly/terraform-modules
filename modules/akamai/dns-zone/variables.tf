variable "zones" {
  description = "Map of zones keyed by an arbitrary unique identifier. Keys only pick the for_each instance and appear in resource addresses and outputs. Zone names must be unique ignoring case across the map (validated)."
  type = map(object({
    zone                     = string
    contract                 = string
    group                    = string
    type                     = string
    masters                  = optional(list(string), [])
    target                   = optional(string)
    comment                  = optional(string, "Managed by Terraform")
    sign_and_serve           = optional(bool, false)
    sign_and_serve_algorithm = optional(string)
    end_customer_id          = optional(string)
    tsig_key = optional(object({
      name      = string
      algorithm = string
      secret    = string
    }))
    outbound_zone_transfer = optional(object({
      acl            = optional(list(string))
      enabled        = optional(bool, false)
      notify_targets = optional(list(string))
      tsig_key = optional(object({
        name      = string
        algorithm = string
        secret    = string
      }))
    }))
    multi_provider_dnssec = optional(object({
      enabled = bool
      webhook = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for z in var.zones : contains(["primary", "secondary", "alias"], z.type)])
    error_message = "type must be one of primary, secondary, alias (lowercase in config; the resource stores it uppercased)."
  }

  validation {
    condition     = alltrue([for z in var.zones : length(z.zone) >= 1 && !can(regex("\\.$", z.zone))])
    error_message = "zone must not be empty and must not have a trailing dot."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type != "secondary" || length(z.masters) >= 1])
    error_message = "secondary zones must set at least one masters entry."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type == "secondary" || length(z.masters) == 0])
    error_message = "masters is only valid for secondary zones."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type != "alias" || (z.target != null && length(z.target) >= 1)])
    error_message = "alias zones must set target (the name of the zone they alias)."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type == "alias" || z.target == null])
    error_message = "target is only valid for alias zones."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type != "alias" || z.target == null || lower(z.target) != lower(z.zone)])
    error_message = "an alias zone cannot target itself."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.type == "secondary" || z.tsig_key == null])
    error_message = "tsig_key is only valid for secondary zones."
  }

  validation {
    condition = alltrue([for z in var.zones :
      (z.tsig_key == null || contains(["hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT"], z.tsig_key.algorithm)) &&
    (z.outbound_zone_transfer == null || z.outbound_zone_transfer.tsig_key == null || contains(["hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT"], z.outbound_zone_transfer.tsig_key.algorithm))])
    error_message = "tsig_key.algorithm must be one of hmac-md5, hmac-sha1, hmac-sha224, hmac-sha256, hmac-sha384, hmac-sha512, HMAC-MD5.SIG-ALG.REG.INT."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.sign_and_serve_algorithm == null || (z.type != "alias" && z.sign_and_serve)])
    error_message = "sign_and_serve_algorithm can only be set on a zone that is actually signed (sign_and_serve = true; it has no effect on alias zones)."
  }

  validation {
    condition     = alltrue([for z in var.zones : z.multi_provider_dnssec == null || !z.multi_provider_dnssec.enabled || (z.type != "alias" && z.sign_and_serve)])
    error_message = "multi_provider_dnssec.enabled = true requires the zone to be effectively signed: sign_and_serve = true on a primary or secondary zone (it is discarded for alias zones and the API rejects the combination)."
  }

  validation {
    condition     = length(distinct([for z in var.zones : lower(z.zone)])) == length(var.zones)
    error_message = "zone names must be unique ignoring case: DNS identity is case-insensitive, so example.org and EXAMPLE.ORG identify the same zone."
  }
}
