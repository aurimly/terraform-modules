output "zone_ids" {
  description = "Map of zone name => zone ID."
  value       = { for name, zone in ns1_zone.zone : name => zone.id }
}

output "zone_name_servers" {
  description = "Map of zone name => list of nameserver hostnames assigned to the zone."
  value       = { for name, zone in ns1_zone.zone : name => split(",", zone.dns_servers) }
}

output "zone_dnssec_states" {
  description = "Map of zone name => DNSSEC enablement state."
  value       = { for name, zone in ns1_zone.zone : name => zone.dnssec }
}

output "zone_hostmasters" {
  description = "Map of zone name => hostmaster address."
  value       = { for name, zone in ns1_zone.zone : name => zone.hostmaster }
}

output "primary_ns_record_fqdns" {
  description = "Map of \"<zone>/<domain>\" => FQDN of the NS records created for custom primaries."
  value       = { for key, record in ns1_record.primary_ns : key => record.domain }
}
