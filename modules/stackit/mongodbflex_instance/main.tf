terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_mongodbflex_instance" "instance" {
  for_each = var.instances

  project_id      = each.value.project_id
  name            = each.value.name
  acl             = each.value.acl
  flavor          = each.value.flavor
  replicas        = each.value.replicas
  storage         = each.value.storage
  version         = each.value.version
  options         = each.value.options
  backup_schedule = each.value.backup_schedule
  region          = each.value.region
}
