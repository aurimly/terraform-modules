terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_affinity_group" "affinity_group" {
  for_each = var.affinity_groups

  project_id = each.value.project_id
  region     = each.value.region
  name       = each.value.name
  policy     = each.value.policy
}
