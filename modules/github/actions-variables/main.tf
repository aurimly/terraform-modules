terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_actions_variable" "variable" {
  for_each      = var.variables
  repository    = var.repository
  variable_name = each.key
  value         = each.value.value
}
