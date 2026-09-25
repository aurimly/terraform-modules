output "registry_ids" {
  description = "Map of rule key => registry ID (the account ID owning the rule)."
  value       = { for k, r in aws_ecr_pull_through_cache_rule.rule : k => r.registry_id }
}
