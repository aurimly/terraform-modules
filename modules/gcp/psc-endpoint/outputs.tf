output "endpoint_ips" {
  description = "Map of endpoint key => the reserved internal IP (the IP consumers connect to)."
  value       = { for k, ep in google_compute_address.psc_address : k => ep.address }
}

output "address_names" {
  description = "Map of endpoint key => reserved IP address name."
  value       = { for k, ep in google_compute_address.psc_address : k => ep.name }
}

output "address_self_links" {
  description = "Map of endpoint key => reserved IP address self link."
  value       = { for k, ep in google_compute_address.psc_address : k => ep.self_link }
}

output "endpoint_self_links" {
  description = "Map of endpoint key => forwarding rule self link."
  value       = { for k, ep in google_compute_forwarding_rule.psc_forwarding_rule : k => ep.self_link }
}

output "psc_connection_ids" {
  description = "Map of endpoint key => PSC connection id of the forwarding rule."
  value       = { for k, ep in google_compute_forwarding_rule.psc_forwarding_rule : k => ep.psc_connection_id }
}

output "psc_connection_statuses" {
  description = "Map of endpoint key => PSC connection status of the forwarding rule (STATUS_UNSPECIFIED, PENDING, ACCEPTED, REJECTED or CLOSED)."
  value       = { for k, ep in google_compute_forwarding_rule.psc_forwarding_rule : k => ep.psc_connection_status }
}

output "service_names" {
  description = "Map of endpoint key => the internal service DNS name that resolves to the endpoint IP."
  value       = { for k, ep in google_compute_forwarding_rule.psc_forwarding_rule : k => ep.service_name }
}
