terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_kms_keyring" "keyring" {
  for_each = var.keyrings

  project_id   = each.value.project_id
  display_name = each.value.display_name
  description  = each.value.description
  region       = each.value.region
}
