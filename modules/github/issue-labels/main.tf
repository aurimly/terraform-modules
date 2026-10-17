terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_issue_label" "label" {
  for_each = var.labels

  repository  = var.repository
  name        = each.key
  color       = each.value.color
  description = each.value.description
}
