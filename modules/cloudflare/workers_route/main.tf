terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_workers_route" "route" {
  for_each = var.routes

  zone_id = coalesce(each.value.zone_id, var.zone_id)
  pattern = each.value.pattern
  script  = each.value.script

  lifecycle {
    precondition {
      condition     = (each.value.zone_id != null && each.value.zone_id != "") || var.zone_id != ""
      error_message = "route \"${each.key}\" must set zone_id, or the module-level zone_id fallback must be set."
    }
  }
}
