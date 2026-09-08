terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_network" "network" {
  for_each = var.networks

  project_id         = each.value.project_id
  name               = each.value.name
  region             = each.value.region
  routed             = each.value.routed
  dhcp               = each.value.dhcp
  labels             = each.value.labels
  ipv4_prefix        = each.value.ipv4_prefix
  ipv4_prefix_length = each.value.ipv4_prefix_length
  ipv4_gateway       = each.value.ipv4_gateway
  no_ipv4_gateway    = each.value.no_ipv4_gateway
  ipv4_nameservers   = each.value.ipv4_nameservers
  ipv6_prefix        = each.value.ipv6_prefix
  ipv6_prefix_length = each.value.ipv6_prefix_length
  ipv6_gateway       = each.value.ipv6_gateway
  no_ipv6_gateway    = each.value.no_ipv6_gateway
  ipv6_nameservers   = each.value.ipv6_nameservers
}
