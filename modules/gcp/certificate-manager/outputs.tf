output "dns_authorization_ids" {
  description = "Map of DNS authorization key => id (projects/{project}/locations/{location}/dnsAuthorizations/{name})."
  value       = { for k, a in google_certificate_manager_dns_authorization.dns_authorization : k => a.id }
}

output "dns_resource_records" {
  description = "Map of DNS authorization key => list of DNS records to add ({name, type, data}) for the authorization to work."
  value       = { for k, a in google_certificate_manager_dns_authorization.dns_authorization : k => a.dns_resource_record }
}

output "certificate_ids" {
  description = "Map of certificate key => id (projects/{project}/locations/{location}/certificates/{name})."
  value       = { for k, c in google_certificate_manager_certificate.certificate : k => c.id }
}

output "certificate_map_ids" {
  description = "Map of certificate map key => id (projects/{project}/locations/global/certificateMaps/{name})."
  value       = { for k, m in google_certificate_manager_certificate_map.map : k => m.id }
}

output "certificate_map_entry_ids" {
  description = "Map of certificate map entry key => id (projects/{project}/locations/global/certificateMaps/{map}/certificateMapEntries/{name})."
  value       = { for k, e in google_certificate_manager_certificate_map_entry.entry : k => e.id }
}
