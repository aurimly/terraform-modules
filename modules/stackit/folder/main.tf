terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.66.0"
    }
  }
}

resource "stackit_resourcemanager_folder" "folder" {
  for_each = var.folders

  name                = each.value.name
  owner_email         = each.value.owner_email
  parent_container_id = each.value.parent_container_id
  labels              = each.value.labels
}
