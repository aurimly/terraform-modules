terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server_update_enable" "this" {
  for_each = var.server_update_enables

  project_id       = each.value.project_id
  server_id        = each.value.server_id
  update_policy_id = each.value.update_policy_id
  region           = each.value.region
}
