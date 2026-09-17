terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_vpn_connection" "connection" {
  for_each = var.connections

  project_id     = each.value.project_id
  gateway_id     = each.value.gateway_id
  display_name   = each.value.display_name
  tunnel1        = each.value.tunnel1
  tunnel2        = each.value.tunnel2
  region         = each.value.region
  enabled        = each.value.enabled
  labels         = each.value.labels
  local_subnets  = each.value.local_subnets
  remote_subnets = each.value.remote_subnets
  static_routes  = each.value.static_routes
}
