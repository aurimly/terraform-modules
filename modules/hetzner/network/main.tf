terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_network" "network" {
  for_each = var.networks

  name                     = each.value.name
  ip_range                 = each.value.ip_range
  labels                   = each.value.labels
  delete_protection        = each.value.delete_protection
  expose_routes_to_vswitch = each.value.expose_routes_to_vswitch
}
