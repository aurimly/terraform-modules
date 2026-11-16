variable "zone_id" {
  description = "Fallback Cloudflare zone ID used when a hostname entry or the fallback origin omits zone_id. Must be set if any entry omits zone_id."
  type        = string
  default     = ""
}

variable "hostnames" {
  description = "Map of SSL for SaaS custom hostnames keyed by an arbitrary unique identifier. Each entry creates one cloudflare_custom_hostname in the zone resolved from the entry's zone_id or the module-level fallback. The map key is the disambiguator — hostnames themselves are unique per zone and validated."
  type = map(object({
    hostname             = string
    zone_id              = optional(string)
    custom_metadata      = optional(map(string))
    custom_origin_server = optional(string)
    custom_origin_sni    = optional(string)
    ssl = optional(object({
      bundle_method         = optional(string)
      certificate_authority = optional(string)
      cloudflare_branding   = optional(bool)
      custom_certificate    = optional(string)
      custom_csr_id         = optional(string)
      custom_key            = optional(string)
      method                = optional(string)
      type                  = optional(string)
      wildcard              = optional(bool)
      custom_cert_bundle = optional(list(object({
        custom_certificate = string
        custom_key         = string
      })))
      settings = optional(object({
        ciphers         = optional(list(string))
        early_hints     = optional(string)
        http2           = optional(string)
        min_tls_version = optional(string)
        tls_1_3         = optional(string)
      }))
    }))
  }))

  validation {
    condition     = alltrue([for h in var.hostnames : length(trimspace(h.hostname)) > 0])
    error_message = "hostname must not be empty or whitespace; it is the custom hostname that points traffic at the zone via CNAME."
  }

  validation {
    condition = alltrue(flatten([
      for key, h in var.hostnames : [
        for other_key, o in var.hostnames :
        key == other_key || lower(h.hostname) != lower(o.hostname) || ((h.zone_id != null && h.zone_id != "") ? h.zone_id : var.zone_id) != ((o.zone_id != null && o.zone_id != "") ? o.zone_id : var.zone_id)
      ]
    ]))
    error_message = "hostnames must be unique within their zone, case-insensitively — uniqueness is judged against the resolved zone_id (the entry's own or the module-level fallback), and two entries sharing a resolved zone and hostname conflict at apply."
  }

  validation {
    condition     = alltrue([for h in var.hostnames : h.ssl == null || h.ssl.type == null || h.ssl.type == "dv"])
    error_message = "ssl.type must be \"dv\" — custom hostnames only support Domain Validation certificates; every other value is rejected by the API."
  }

  validation {
    condition     = alltrue([for h in var.hostnames : h.ssl == null || h.ssl.method == null || contains(["http", "txt", "email"], h.ssl.method)])
    error_message = "ssl.method must be one of http, txt or email — the Domain Validation method used to validate the hostname."
  }

  validation {
    condition     = alltrue([for h in var.hostnames : h.ssl == null || h.ssl.bundle_method == null || contains(["ubiquitous", "optimal", "force"], h.ssl.bundle_method)])
    error_message = "ssl.bundle_method must be one of ubiquitous, optimal or force."
  }

  validation {
    condition     = alltrue([for h in var.hostnames : h.ssl == null || h.ssl.certificate_authority == null || contains(["digicert", "google", "lets_encrypt", "ssl_com"], h.ssl.certificate_authority)])
    error_message = "ssl.certificate_authority must be one of digicert, google, lets_encrypt or ssl_com."
  }

  validation {
    condition     = alltrue([for h in var.hostnames : h.ssl == null || h.ssl.custom_cert_bundle == null || length(h.ssl.custom_cert_bundle) >= 1 && length(h.ssl.custom_cert_bundle) <= 2])
    error_message = "ssl.custom_cert_bundle must hold one or two certificate/key pairs — the API accepts at most two pairs for hostname/wildcard coverage."
  }

  validation {
    condition = alltrue(flatten([
      for h in var.hostnames : h.ssl == null || h.ssl.settings == null ? [true] : [
        for enum in [h.ssl.settings.early_hints, h.ssl.settings.http2, h.ssl.settings.tls_1_3] :
        enum == null || contains(["on", "off"], enum)
      ]
    ]))
    error_message = "ssl.settings early_hints, http2 and tls_1_3 must be \"on\" or \"off\"."
  }

  validation {
    condition = alltrue([
      for h in var.hostnames : h.ssl == null || h.ssl.settings == null || h.ssl.settings.min_tls_version == null || contains(["1.0", "1.1", "1.2", "1.3"], h.ssl.settings.min_tls_version)
    ])
    error_message = "ssl.settings.min_tls_version must be one of 1.0, 1.1, 1.2 or 1.3."
  }
}

variable "fallback_origin" {
  description = "Optional zone fallback origin for custom hostnames whose traffic does not route to a specific custom origin. One per zone — the origin must exist as a DNS record in the zone before the fallback origin activates. Created as one cloudflare_custom_hostname_fallback_origin when set."
  type = object({
    origin  = string
    zone_id = optional(string)
  })
  default = null

  validation {
    condition     = var.fallback_origin == null || length(trimspace(var.fallback_origin.origin)) > 0
    error_message = "origin must be a non-empty hostname in the zone; it is where custom hostnames' traffic is sent by default."
  }
}
