terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_custom_hostname" "custom_hostname" {
  for_each = var.hostnames

  zone_id  = (each.value.zone_id != null && each.value.zone_id != "") ? each.value.zone_id : var.zone_id
  hostname = each.value.hostname

  custom_metadata      = each.value.custom_metadata
  custom_origin_server = each.value.custom_origin_server
  custom_origin_sni    = each.value.custom_origin_sni

  ssl = each.value.ssl == null ? null : {
    bundle_method         = each.value.ssl.bundle_method
    certificate_authority = each.value.ssl.certificate_authority
    cloudflare_branding   = each.value.ssl.cloudflare_branding
    custom_certificate    = each.value.ssl.custom_certificate
    custom_csr_id         = each.value.ssl.custom_csr_id
    custom_key            = each.value.ssl.custom_key
    method                = each.value.ssl.method
    type                  = each.value.ssl.type
    wildcard              = each.value.ssl.wildcard
    custom_cert_bundle = each.value.ssl.custom_cert_bundle == null ? null : [
      for pair in each.value.ssl.custom_cert_bundle : {
        custom_certificate = pair.custom_certificate
        custom_key         = pair.custom_key
      }
    ]
    settings = each.value.ssl.settings == null ? null : {
      ciphers         = each.value.ssl.settings.ciphers
      early_hints     = each.value.ssl.settings.early_hints
      http2           = each.value.ssl.settings.http2
      min_tls_version = each.value.ssl.settings.min_tls_version
      tls_1_3         = each.value.ssl.settings.tls_1_3
    }
  }

  lifecycle {
    precondition {
      condition     = (each.value.zone_id != null && each.value.zone_id != "") || var.zone_id != ""
      error_message = "custom hostname \"${each.key}\" must set zone_id, or the module-level zone_id fallback must be set."
    }
  }
}

resource "cloudflare_custom_hostname_fallback_origin" "fallback_origin" {
  for_each = var.fallback_origin != null ? { "1" = true } : {}

  zone_id = (var.fallback_origin.zone_id != null && var.fallback_origin.zone_id != "") ? var.fallback_origin.zone_id : var.zone_id
  origin  = var.fallback_origin.origin

  lifecycle {
    precondition {
      condition     = (var.fallback_origin.zone_id != null && var.fallback_origin.zone_id != "") || var.zone_id != ""
      error_message = "fallback_origin must set zone_id, or the module-level zone_id fallback must be set."
    }
  }
}
