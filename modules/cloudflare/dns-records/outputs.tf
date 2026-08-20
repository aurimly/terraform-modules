output "record_ids" {
  description = "Map of record key => record ID."
  value       = { for k, r in cloudflare_dns_record.record : k => r.id }
}

output "record_names" {
  description = "Map of record key => record name (e.g. '@', 'www'). v5 has no computed hostname attribute."
  value       = { for k, r in cloudflare_dns_record.record : k => r.name }
}

output "record_contents" {
  description = "Map of record key => content string. Null for records the API stores in data form (CAA data form)."
  value       = { for k, r in cloudflare_dns_record.record : k => r.content }
}
