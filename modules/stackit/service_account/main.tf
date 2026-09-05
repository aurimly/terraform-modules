terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.113.0"
    }
  }
}

resource "stackit_service_account" "service_account" {
  for_each = var.service_accounts

  name       = each.value.name
  project_id = each.value.project_id
}
