output "zone_ids" {
  description = "Map of zone name => zone ID."
  value       = { for name, zone in cloudflare_zone.zone : name => zone.id }
}

output "zone_names" {
  description = "Map of zone name => zone name as managed in Cloudflare."
  value       = { for name, zone in cloudflare_zone.zone : name => zone.name }
}

output "zone_statuses" {
  description = "Map of zone name => zone status."
  value       = { for name, zone in cloudflare_zone.zone : name => zone.status }
}

output "zone_name_servers" {
  description = "Map of zone name => list of assigned Cloudflare nameservers."
  value       = { for name, zone in cloudflare_zone.zone : name => zone.name_servers }
}
