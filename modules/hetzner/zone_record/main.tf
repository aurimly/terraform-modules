terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.60.0"
    }
  }
}

resource "hcloud_zone_record" "record" {
  for_each = var.records

  zone    = var.zone
  name    = each.value.name
  type    = each.value.type
  value   = each.value.value
  comment = each.value.comment
}
