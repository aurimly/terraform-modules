terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_network_area_region" "network_area_region" {
  for_each = var.network_area_regions

  organization_id = each.value.organization_id
  network_area_id = each.value.network_area_id
  region          = each.value.region
  ipv4 = {
    transfer_network      = each.value.ipv4.transfer_network
    network_ranges        = [for p in sort(values(each.value.ipv4.network_ranges)) : { prefix = p }]
    default_nameservers   = each.value.ipv4.default_nameservers
    default_prefix_length = each.value.ipv4.default_prefix_length
    max_prefix_length     = each.value.ipv4.max_prefix_length
    min_prefix_length     = each.value.ipv4.min_prefix_length
  }
}
