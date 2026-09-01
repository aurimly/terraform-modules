terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.113.0"
    }
  }
}

resource "stackit_authorization_project_role_assignment" "project_role_assignment" {
  for_each = var.role_assignments

  resource_id = each.value.resource_id
  role        = each.value.role
  subject     = each.value.subject
}
