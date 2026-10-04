terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_primary_ip" "primary_ip" {
  for_each = var.primary_ips

  name              = each.value.name
  type              = each.value.type
  location          = each.value.location
  assignee_id       = each.value.assignee_id
  assignee_type     = each.value.assignee_type
  auto_delete       = each.value.auto_delete
  delete_protection = each.value.delete_protection
  labels            = each.value.labels
}
