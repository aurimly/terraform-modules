terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_postgresflex_database" "database" {
  for_each = var.databases

  project_id  = each.value.project_id
  instance_id = each.value.instance_id
  name        = each.value.name
  owner       = each.value.owner
  region      = each.value.region
}
