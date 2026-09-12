terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_postgresflex_instance" "instance" {
  for_each = var.instances

  project_id      = each.value.project_id
  name            = each.value.name
  version         = each.value.version
  backup_schedule = each.value.backup_schedule
  flavor_id       = each.value.flavor_id
  region          = each.value.region
  retention_days  = each.value.retention_days
  storage         = each.value.storage
  network         = each.value.network
  encryption      = each.value.encryption
}
