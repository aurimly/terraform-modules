terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_dns_zone" "zone" {
  for_each = var.zones

  project_id      = each.value.project_id
  name            = each.value.name
  dns_name        = each.value.dns_name
  type            = each.value.type
  acl             = each.value.acl
  active          = each.value.active
  contact_email   = each.value.contact_email
  default_ttl     = each.value.default_ttl
  description     = each.value.description
  expire_time     = each.value.expire_time
  is_reverse_zone = each.value.is_reverse_zone
  negative_cache  = each.value.negative_cache
  primaries       = each.value.primaries
  refresh_time    = each.value.refresh_time
  retry_time      = each.value.retry_time
}
