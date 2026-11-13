terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_email_routing_rule" "rule" {
  for_each = var.rules

  zone_id  = each.value.zone_id
  matchers = each.value.matchers
  actions  = each.value.actions

  enabled          = each.value.enabled
  name             = each.value.name
  priority         = each.value.priority
  source           = each.value.source
  owner_worker_tag = each.value.owner_worker_tag
}

resource "cloudflare_email_routing_catch_all" "catch_all" {
  for_each = var.catch_all_rules

  zone_id  = each.value.zone_id
  matchers = [{ type = "all" }]
  actions  = each.value.actions

  enabled          = each.value.enabled
  name             = each.value.name
  source           = each.value.source
  owner_worker_tag = each.value.owner_worker_tag
}
