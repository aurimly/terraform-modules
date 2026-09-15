terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_service_account_key" "service_account_key" {
  for_each = var.service_account_keys

  project_id            = each.value.project_id
  service_account_email = each.value.service_account_email
  public_key            = each.value.public_key
  ttl_days              = each.value.ttl_days
  rotate_when_changed   = each.value.rotate_when_changed
}
