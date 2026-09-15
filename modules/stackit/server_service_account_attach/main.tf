terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server_service_account_attach" "server_service_account_attach" {
  for_each = var.server_service_account_attaches

  project_id            = each.value.project_id
  region                = each.value.region
  server_id             = each.value.server_id
  service_account_email = each.value.service_account_email
}
