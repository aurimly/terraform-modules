terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_dns_record" "record" {
  for_each = var.records

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  ttl      = each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
  tags     = each.value.tags

  # content and data are mutually exclusive in the Cloudflare API. Use content
  # when set; fall back to data for records the API returns in data form (CAA).
  content = each.value.content
  data    = each.value.data
}
