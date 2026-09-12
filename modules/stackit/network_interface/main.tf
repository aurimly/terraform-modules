terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_network_interface" "network_interface" {
  for_each = var.network_interfaces

  project_id         = each.value.project_id
  network_id         = each.value.network_id
  region             = each.value.region
  name               = each.value.name
  ipv4               = each.value.ipv4
  allowed_addresses  = each.value.allowed_addresses
  security           = each.value.security
  security_group_ids = each.value.security_group_ids
  labels             = each.value.labels
}
