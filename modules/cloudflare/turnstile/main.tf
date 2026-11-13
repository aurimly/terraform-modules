terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_turnstile_widget" "widget" {
  for_each = var.widgets

  account_id = coalesce(each.value.account_id, var.account_id)
  name       = each.value.name
  domains    = each.value.domains
  mode       = each.value.mode

  bot_fight_mode  = each.value.bot_fight_mode
  clearance_level = each.value.clearance_level
  ephemeral_id    = each.value.ephemeral_id
  offlabel        = each.value.offlabel
  region          = each.value.region

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "widget \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }
  }
}
