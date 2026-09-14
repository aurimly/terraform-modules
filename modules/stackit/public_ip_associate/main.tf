terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_public_ip_associate" "public_ip_associate" {
  for_each = var.public_ip_associates

  project_id           = each.value.project_id
  region               = each.value.region
  public_ip_id         = each.value.public_ip_id
  network_interface_id = each.value.network_interface_id
}
