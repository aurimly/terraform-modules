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
}

locals {
  zone_settings = flatten([
    for zone_name, zone_cfg in var.zones : [
      for setting_id, value in zone_cfg.settings : {
        zone_name  = zone_name
        setting_id = setting_id
        value      = value
      }
    ]
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
