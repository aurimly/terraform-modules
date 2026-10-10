terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

resource "github_team" "team" {
  for_each = var.teams

  name                 = each.value.name
  description          = each.value.description
  privacy              = each.value.privacy
  notification_setting = each.value.notification_setting
  parent_team_id       = each.value.parent_team_key != null ? github_team.team[each.value.parent_team_key].id : null
}

resource "github_team_membership" "membership" {
  for_each = {
    for pair in flatten([
      for tk, t in var.teams : [
        for mk, m in t.members : {
          key      = "${tk}:${mk}"
          team_key = tk
          username = m.username
          role     = m.role
        }
      ]
    ]) : pair.key => pair
  }

  team_id  = github_team.team[each.value.team_key].id
  username = each.value.username
  role     = each.value.role
}
