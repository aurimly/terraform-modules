terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_observability_credential" "credential" {
  for_each = var.credentials

  project_id          = each.value.project_id
  instance_id         = each.value.instance_id
  description         = each.value.description
  rotate_when_changed = each.value.rotate_when_changed
}
