terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_actions_organization_variable" "variable" {
  for_each = var.variables

  variable_name           = each.key
  value                   = each.value.value
  visibility              = each.value.visibility
  selected_repository_ids = each.value.selected_repository_ids
}
