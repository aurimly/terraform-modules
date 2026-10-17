terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

locals {
  secret_selected = {
    for key, secret in var.secrets : key => secret
    if secret.selected_repository_ids != null
  }
}

resource "github_actions_organization_secret" "secret" {
  for_each = var.secrets

  secret_name = each.key
  value       = each.value.value
  visibility  = each.value.visibility
}

resource "github_actions_organization_secret_repositories" "secret_repositories" {
  for_each = local.secret_selected

  secret_name             = github_actions_organization_secret.secret[each.key].secret_name
  selected_repository_ids = each.value.selected_repository_ids
}
