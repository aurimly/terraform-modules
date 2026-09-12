terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_secretsmanager_user" "user" {
  for_each = var.users

  project_id          = each.value.project_id
  instance_id         = each.value.instance_id
  description         = each.value.description
  write_enabled       = each.value.write_enabled
  rotate_when_changed = each.value.rotate_when_changed
}
