terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_kms_key" "key" {
  for_each = var.keys

  project_id   = each.value.project_id
  keyring_id   = each.value.keyring_id
  display_name = each.value.display_name
  algorithm    = each.value.algorithm
  protection   = each.value.protection
  purpose      = each.value.purpose
  access_scope = each.value.access_scope
  description  = each.value.description
  import_only  = each.value.import_only
  region       = each.value.region
}
