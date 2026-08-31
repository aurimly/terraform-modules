terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.66.0"
    }
  }
}

resource "stackit_resourcemanager_project" "project" {
  for_each = var.projects

  name                = each.value.name
  owner_email         = each.value.owner_email
  parent_container_id = each.value.parent_container_id
  labels              = each.value.labels
}
