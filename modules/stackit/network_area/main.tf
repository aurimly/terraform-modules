terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_network_area" "network_area" {
  for_each = var.network_areas

  organization_id = each.value.organization_id
  name            = each.value.name
  labels          = each.value.labels
}
