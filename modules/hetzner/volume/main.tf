terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_volume" "volume" {
  for_each = var.volumes

  name              = each.value.name
  size              = each.value.size
  location          = each.value.location
  server_id         = each.value.server_id
  automount         = each.value.automount
  format            = each.value.format
  labels            = each.value.labels
  delete_protection = each.value.delete_protection
}
