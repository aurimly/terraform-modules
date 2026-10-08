terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_ruleset" "ruleset" {
  for_each = var.rulesets

  zone_id     = var.zone_id
  name        = each.value.name
  phase       = each.value.phase
  kind        = "custom"
  description = each.value.description
  rules       = each.value.rules
}
