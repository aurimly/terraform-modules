output "connector_names" {
  description = "Map of connector key => connector name."
  value       = { for k, c in google_vpc_access_connector.connector : k => c.name }
}

output "connector_ids" {
  description = "Map of connector key => fully-qualified connector ID (projects/{project}/locations/{region}/connectors/{name})."
  value       = { for k, c in google_vpc_access_connector.connector : k => c.id }
}

output "connector_self_links" {
  description = "Map of connector key => connector self link."
  value       = { for k, c in google_vpc_access_connector.connector : k => c.self_link }
}

output "connector_states" {
  description = "Map of connector key => connector state (READY, CREATING, DELETING, ...)."
  value       = { for k, c in google_vpc_access_connector.connector : k => c.state }
}
