terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server_network_interface_attach" "server_network_interface_attach" {
  for_each = var.server_network_interface_attaches

  project_id           = each.value.project_id
  region               = each.value.region
  server_id            = each.value.server_id
  network_interface_id = each.value.network_interface_id
}
