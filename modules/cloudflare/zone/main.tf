terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_zone" "zone" {
  for_each = var.zones

  name    = each.key
  account = { id = coalesce(each.value.account_id, var.account_id) }
  type    = each.value.type
  paused  = each.value.paused

  lifecycle {
    precondition {
      condition     = (each.value.account_id != null && each.value.account_id != "") || var.account_id != ""
      error_message = "zone \"${each.key}\" must set account_id, or the module-level account_id fallback must be set."
    }

    precondition {
      condition     = length(setintersection(keys(each.value.settings), keys(each.value.typed_settings))) == 0
      error_message = "zone \"${each.key}\" must not set the same setting_id in both settings and typed_settings."
    }
  }
}

locals {
  zone_settings = flatten([
    for zone_name, zone_cfg in var.zones : concat(
      [
        for setting_id, value in zone_cfg.settings : {
          zone_name  = zone_name
          setting_id = setting_id
          value      = value
        }
      ],
      [
        for setting_id, value in zone_cfg.typed_settings : {
          zone_name  = zone_name
          setting_id = setting_id
          value      = jsondecode(value)
        }
      ]
    )
  ])
}

resource "cloudflare_zone_setting" "settings" {
  for_each = {
    for s in local.zone_settings : "${s.zone_name}/${s.setting_id}" => s
  }

  zone_id    = cloudflare_zone.zone[each.value.zone_name].id
  setting_id = each.value.setting_id
  value      = each.value.value
}
