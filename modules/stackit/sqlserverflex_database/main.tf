terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_sqlserverflex_database" "database" {
  for_each = var.databases

  project_id    = each.value.project_id
  instance_id   = each.value.instance_id
  name          = each.value.name
  owner         = each.value.owner
  collation     = each.value.collation
  compatibility = each.value.compatibility
  region        = each.value.region
}
