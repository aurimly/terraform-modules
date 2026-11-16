terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_snippet" "snippet" {
  for_each = var.snippets

  zone_id      = var.zone_id
  snippet_name = each.value.snippet_name
  files        = each.value.files
  metadata     = { main_module = coalesce(each.value.main_module, each.value.files[0].name) }
}

resource "cloudflare_snippet_rules" "rules" {
  for_each = length(var.rules) > 0 ? { "1" = true } : {}

  zone_id = var.zone_id
  rules   = [for rule in var.rules : { expression = rule.expression, snippet_name = rule.snippet_name, description = rule.description, enabled = rule.enabled }]
}
