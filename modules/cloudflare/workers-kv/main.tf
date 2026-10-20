terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_workers_kv_namespace" "namespace" {
  for_each = var.namespaces

  account_id   = coalesce(each.value.account_id, var.account_id)
  title        = each.value.title
  jurisdiction = each.value.jurisdiction
  mode         = each.value.mode

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "namespace \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}
