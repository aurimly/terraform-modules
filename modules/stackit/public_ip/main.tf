terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_public_ip" "public_ip" {
  for_each = var.public_ips

  project_id           = each.value.project_id
  region               = each.value.region
  network_interface_id = each.value.network_interface_id
  labels               = each.value.labels
}
