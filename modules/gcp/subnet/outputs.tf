output "subnet_names" {
  description = "Map of subnet key => subnetwork name."
  value       = { for k, s in google_compute_subnetwork.subnet : k => s.name }
}

output "subnet_self_links" {
  description = "Map of subnet key => subnetwork self link."
  value       = { for k, s in google_compute_subnetwork.subnet : k => s.self_link }
}

output "subnet_gateway_addresses" {
  description = "Map of subnet key => gateway address selected by GCP for default routes out of the subnetwork."
  value       = { for k, s in google_compute_subnetwork.subnet : k => s.gateway_address }
}
