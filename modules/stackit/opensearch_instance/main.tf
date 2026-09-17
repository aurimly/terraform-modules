terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_opensearch_instance" "instance" {
  for_each = var.instances

  project_id = each.value.project_id
  name       = each.value.name
  version    = each.value.version
  plan_name  = each.value.plan_name
  region     = each.value.region
  parameters = each.value.parameters
}
