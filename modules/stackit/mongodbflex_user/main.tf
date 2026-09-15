terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_mongodbflex_user" "user" {
  for_each = var.users

  project_id          = each.value.project_id
  instance_id         = each.value.instance_id
  username            = each.value.username
  roles               = each.value.roles
  database            = each.value.database
  region              = each.value.region
  rotate_when_changed = each.value.rotate_when_changed
}
