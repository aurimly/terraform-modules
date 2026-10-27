output "membership_ids" {
  description = "Map of member key => resource ID (<organization>:<username>, the import form)."
  value       = { for k, m in github_membership.membership : k => m.id }
}
