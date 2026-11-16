output "snippet_ids" {
  description = "Map of key => snippet ID. The import identifier for a snippet is <zone_id>/<snippet_name>, not this generated ID."
  value       = { for key, snippet in cloudflare_snippet.snippet : key => snippet.id }
}

output "rule_ids" {
  description = "Rule IDs in evaluation order, or an empty list when var.rules is empty. Positional — indexes shift when a middle rule is removed, so do not treat positions as stable identifiers across changes."
  value       = flatten([for rules in cloudflare_snippet_rules.rules : [for rule in rules.rules : rule.id]])
}
