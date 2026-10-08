output "ruleset_ids" {
  description = "Ruleset IDs, keyed by ruleset key."
  value       = { for k, r in cloudflare_ruleset.ruleset : k => r.id }
}

output "ruleset_versions" {
  description = "Ruleset versions (the API's version counter per ruleset), keyed by ruleset key."
  value       = { for k, r in cloudflare_ruleset.ruleset : k => r.version }
}
