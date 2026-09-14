terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server_volume_attach" "server_volume_attach" {
  for_each = var.server_volume_attaches

  project_id = each.value.project_id
  region     = each.value.region
  server_id  = each.value.server_id
  volume_id  = each.value.volume_id
}
