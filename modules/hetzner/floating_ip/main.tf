terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_floating_ip" "floating_ip" {
  for_each = var.floating_ips

  type              = each.value.type
  name              = each.value.name
  home_location     = each.value.home_location
  server_id         = each.value.server_id
  description       = each.value.description
  labels            = each.value.labels
  delete_protection = each.value.delete_protection
}
