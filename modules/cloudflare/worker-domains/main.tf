terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_workers_custom_domain" "domain" {
  for_each = var.domains

  account_id = var.account_id
  hostname   = each.key
  service    = each.value.service
  zone_id    = coalesce(each.value.zone_id, var.zone_id)
  zone_name  = each.value.zone_name

  lifecycle {
    precondition {
      condition     = (each.value.zone_id != null && each.value.zone_id != "") || var.zone_id != ""
      error_message = "domain \"${each.key}\" must set zone_id, or the module-level zone_id fallback must be set."
    }
  }
}
