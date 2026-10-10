terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_actions_secret" "secret" {
  for_each    = var.secrets
  repository  = var.repository
  secret_name = each.key
  value       = each.value.value
}
