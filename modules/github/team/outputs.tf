output "team_ids" {
  description = "Map of team key => numeric team ID (accepts ID or slug form for other team resources)."
  value       = { for k, t in github_team.team : k => t.id }
}

output "team_slugs" {
  description = "Map of team key => slug. Computed by GitHub from the name; may differ from name when the name contains URL-unsafe characters."
  value       = { for k, t in github_team.team : k => t.slug }
}

output "team_node_ids" {
  description = "Map of team key => GitHub node ID (used by resources that take a node ID, e.g. environment reviewer teams or branch protection)."
  value       = { for k, t in github_team.team : k => t.node_id }
}

output "membership_ids" {
  description = "Map of membership key (\"<team_key>:<member_key>\") => resource ID (team ID:username)."
  value       = { for k, m in github_team_membership.membership : k => m.id }
}
