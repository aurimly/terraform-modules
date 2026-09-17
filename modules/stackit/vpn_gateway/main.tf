terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_vpn_gateway" "gateway" {
  for_each = var.gateways

  project_id         = each.value.project_id
  display_name       = each.value.display_name
  plan_id            = each.value.plan_id
  routing_type       = each.value.routing_type
  availability_zones = each.value.availability_zones
  region             = each.value.region
  labels             = each.value.labels
  bgp                = each.value.bgp
  network_config     = each.value.network_config
}
