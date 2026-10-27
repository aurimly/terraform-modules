terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_repository_collaborators" "collaborators" {
  for_each = var.repositories

  repository = each.value.repository

  dynamic "team" {
    for_each = each.value.teams
    content {
      team_id    = team.value.team_id
      permission = team.value.permission
    }
  }

  dynamic "user" {
    for_each = each.value.users
    content {
      username   = user.value.username
      permission = user.value.permission
    }
  }
}
