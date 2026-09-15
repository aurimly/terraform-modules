terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server_backup_enable" "this" {
  for_each = var.server_backup_enables

  project_id       = each.value.project_id
  server_id        = each.value.server_id
  backup_policy_id = each.value.backup_policy_id
  region           = each.value.region
}
