terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_rdns" "rdns" {
  for_each = var.rdns_entries

  server_id        = each.value.server_id
  primary_ip_id    = each.value.primary_ip_id
  floating_ip_id   = each.value.floating_ip_id
  load_balancer_id = each.value.load_balancer_id
  ip_address       = each.value.ip_address
  dns_ptr          = each.value.dns_ptr
}
