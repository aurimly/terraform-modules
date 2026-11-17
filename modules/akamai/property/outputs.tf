output "property_ids" {
  description = "Map of key => property ID (prp_...). This is the import ID base of akamai_property."
  value       = { for k, p in akamai_property.property : k => p.id }
}

output "property_latest_versions" {
  description = "Map of key => latest property version number. Increments on every rules, hostnames or rule_format change."
  value       = { for k, p in akamai_property.property : k => p.latest_version }
}

output "property_staging_versions" {
  description = "Map of key => property version number active on the staging network (0 when never activated)."
  value       = { for k, p in akamai_property.property : k => p.staging_version }
}

output "property_production_versions" {
  description = "Map of key => property version number active on the production network (0 when never activated)."
  value       = { for k, p in akamai_property.property : k => p.production_version }
}

output "hostnames" {
  description = "Map of key => resolved hostname set as known by the property, including edge_hostname_id, cname_type and cert_status."
  value       = { for k, p in akamai_property.property : k => p.hostnames }
}

output "activation_statuses" {
  description = "Map of key => activation status, for entries that have an activation."
  value       = { for k, a in akamai_property_activation.activation : k => a.status }
}

output "activation_ids" {
  description = "Map of key => activation ID, for entries that have an activation."
  value       = { for k, a in akamai_property_activation.activation : k => a.activation_id }
}
