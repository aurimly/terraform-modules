output "rule_ids" {
  description = "Map of rule key => routing rule ID."
  value       = { for key, rule in cloudflare_email_routing_rule.rule : key => rule.id }
}

output "catch_all_rule_ids" {
  description = "Map of catch-all key => catch-all rule ID."
  value       = { for key, rule in cloudflare_email_routing_catch_all.catch_all : key => rule.id }
}
