output "record_set_names" {
  description = "Map of record key => record FQDN (with trailing dot)."
  value       = { for k, r in google_dns_record_set.record_set : k => r.name }
}

output "record_set_types" {
  description = "Map of record key => record type."
  value       = { for k, r in google_dns_record_set.record_set : k => r.type }
}

output "record_set_ttl" {
  description = "Map of record key => TTL in seconds."
  value       = { for k, r in google_dns_record_set.record_set : k => r.ttl }
}

output "record_set_rrdatas" {
  description = "Map of record key => rrdatas. Only meaningful for records configured via rrdatas (plain A/AAAA/MX/...); routing-policy-backed records return the API-resolved data."
  value       = { for k, r in google_dns_record_set.record_set : k => r.rrdatas }
}
