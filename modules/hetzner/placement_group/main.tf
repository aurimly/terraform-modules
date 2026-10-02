terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_placement_group" "placement_group" {
  for_each = var.placement_groups

  name   = each.value.name
  type   = each.value.type
  labels = each.value.labels
}
