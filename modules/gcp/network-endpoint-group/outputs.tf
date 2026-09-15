output "neg_names" {
  description = "Map of zonal NEG key => NEG name."
  value       = { for k, g in google_compute_network_endpoint_group.neg : k => g.name }
}

output "neg_self_links" {
  description = "Map of zonal NEG key => NEG self link (wire into gcp/load-balancer backends[].group)."
  value       = { for k, g in google_compute_network_endpoint_group.neg : k => g.self_link }
}

output "neg_ids" {
  description = "Map of zonal NEG key => fully-qualified NEG ID (projects/{project}/zones/{zone}/networkEndpointGroups/{name})."
  value       = { for k, g in google_compute_network_endpoint_group.neg : k => g.id }
}

output "regional_neg_names" {
  description = "Map of regional NEG key => NEG name."
  value       = { for k, g in google_compute_region_network_endpoint_group.regional_neg : k => g.name }
}

output "regional_neg_self_links" {
  description = "Map of regional NEG key => NEG self link (wire into gcp/load-balancer backends[].group)."
  value       = { for k, g in google_compute_region_network_endpoint_group.regional_neg : k => g.self_link }
}

output "regional_neg_ids" {
  description = "Map of regional NEG key => fully-qualified NEG ID (projects/{project}/regions/{region}/networkEndpointGroups/{name})."
  value       = { for k, g in google_compute_region_network_endpoint_group.regional_neg : k => g.id }
}

output "endpoint_ids" {
  description = "Map of endpoint key => fully-qualified endpoint ID (projects/{project}/zones/{zone}/networkEndpointGroups/{neg}/{instance}/{ip_address}/{port})."
  value       = { for k, e in google_compute_network_endpoint.endpoint : k => e.id }
}
