terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_d1_database" "database" {
  for_each = var.databases

  account_id            = coalesce(each.value.account_id, var.account_id)
  name                  = each.value.name
  jurisdiction          = each.value.jurisdiction
  primary_location_hint = each.value.primary_location_hint
  read_replication      = each.value.read_replication_mode != null ? { mode = each.value.read_replication_mode } : null

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "database \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}
