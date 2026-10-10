output "protection_ids" {
  description = "Map of protection key => resource ID (<repository_id>:<pattern>)."
  value       = { for k, p in github_branch_protection.protection : k => p.id }
}

output "branch_patterns" {
  description = "Map of protection key => branch pattern actually set."
  value       = { for k, p in var.branch_protections : k => p.branch }
}
