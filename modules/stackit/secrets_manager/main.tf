terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_secretsmanager_instance" "instance" {
  for_each = var.instances

  project_id = each.value.project_id
  name       = each.value.name
  acls       = each.value.acls
  kms_key    = each.value.kms_key
}
