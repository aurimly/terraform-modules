terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_r2_bucket" "bucket" {
  for_each = var.buckets

  account_id    = coalesce(each.value.account_id, var.account_id)
  name          = each.value.name
  location      = each.value.location
  jurisdiction  = each.value.jurisdiction
  storage_class = each.value.storage_class

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "bucket \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}
