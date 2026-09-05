output "network_names" {
  description = "Map of network key => VPC network name."
  value       = { for k, n in google_compute_network.network : k => n.name }
}

output "network_self_links" {
  description = "Map of network key => VPC network self link."
  value       = { for k, n in google_compute_network.network : k => n.self_link }
}

output "network_ids" {
  description = "Map of network key => VPC network ID (projects/{project}/global/networks/{name})."
  value       = { for k, n in google_compute_network.network : k => n.id }
}
