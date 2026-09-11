output "zone_names" {
  description = "Map of zone key => zone name (the identifier `dns-record-sets` expects as managed_zone_name)."
  value       = { for k, z in google_dns_managed_zone.zone : k => z.name }
}

output "zone_dns_names" {
  description = "Map of zone key => DNS name of the zone (FQDN with trailing dot)."
  value       = { for k, z in google_dns_managed_zone.zone : k => z.dns_name }
}

output "zone_name_servers" {
  description = "Map of zone key => set of assigned name servers."
  value       = { for k, z in google_dns_managed_zone.zone : k => z.name_servers }
}

output "zone_ids" {
  description = "Map of zone key => zone id."
  value       = { for k, z in google_dns_managed_zone.zone : k => z.id }
}
