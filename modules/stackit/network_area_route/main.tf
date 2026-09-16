terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_network_area_route" "route" {
  for_each = var.routes

  organization_id = each.value.organization_id
  network_area_id = each.value.network_area_id
  region          = each.value.region
  labels          = each.value.labels
  destination = {
    type  = each.value.destination.type
    value = each.value.destination.value
  }
  next_hop = {
    type  = each.value.next_hop.type
    value = each.value.next_hop.value
  }
}
