terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_zone" "zone" {
  for_each = var.zones

  name                = each.value.name
  mode                = each.value.mode
  ttl                 = each.value.ttl
  labels              = each.value.labels
  delete_protection   = each.value.delete_protection
  primary_nameservers = each.value.primary_nameservers != null ? [for ns in each.value.primary_nameservers : { address = ns.address, port = ns.port, tsig_algorithm = ns.tsig_algorithm, tsig_key = ns.tsig_key }] : null
}
