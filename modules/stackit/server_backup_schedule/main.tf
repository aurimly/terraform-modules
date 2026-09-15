terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server_backup_schedule" "this" {
  for_each = var.server_backup_schedules

  project_id        = each.value.project_id
  server_id         = each.value.server_id
  name              = each.value.name
  rrule             = each.value.rrule
  enabled           = each.value.enabled
  backup_properties = each.value.backup_properties
  region            = each.value.region
}
