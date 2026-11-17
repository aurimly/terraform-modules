output "zone_names" {
  description = "Map of key => zone name. The zone name is also the import ID of akamai_dns_zone."
  value       = { for k, z in akamai_dns_zone.zone : k => z.zone }
}

output "zone_types" {
  description = "Map of key => zone type as stored in state (uppercased by the resource: PRIMARY, SECONDARY, ALIAS)."
  value       = { for k, z in akamai_dns_zone.zone : k => z.type }
}

output "zone_activation_states" {
  description = "Map of key => activation state. Starts at PENDING after create and needs a refresh-only apply to pick up ACTIVE."
  value       = { for k, z in akamai_dns_zone.zone : k => z.activation_state }
}

output "zone_version_ids" {
  description = "Map of key => version ID of the current zone version."
  value       = { for k, z in akamai_dns_zone.zone : k => z.version_id }
}

output "zone_alias_counts" {
  description = "Map of key => number of alias zones pointing at this zone (primary and secondary zones only)."
  value       = { for k, z in akamai_dns_zone.zone : k => z.alias_count }
}
