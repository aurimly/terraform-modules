output "record_ids" {
  description = "Map of record key => record ID."
  value       = { for key, record in ns1_record.record : key => record.id }
}

output "record_fqdns" {
  description = "Map of record key => record name (FQDN, no trailing dot)."
  value       = { for key, record in ns1_record.record : key => record.domain }
}

output "record_types" {
  description = "Map of record key => record type."
  value       = { for key, record in ns1_record.record : key => record.type }
}
