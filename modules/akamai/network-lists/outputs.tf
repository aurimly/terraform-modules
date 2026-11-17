output "network_list_ids" {
  description = "Map of key => unique list ID (<contractId>_<NAME>), the import ID of akamai_networklist_network_list."
  value       = { for k, l in akamai_networklist_network_list.list : k => l.network_list_id }
}

output "network_list_sync_points" {
  description = "Map of key => sync point (increments on every list modification; wired into the activation resource)."
  value       = { for k, l in akamai_networklist_network_list.list : k => l.sync_point }
}

output "network_list_types" {
  description = "Map of key => list type (IP or GEO)."
  value       = { for k, l in akamai_networklist_network_list.list : k => l.type }
}

output "activation_statuses" {
  description = "Map of key => activation status, for entries that have an activation."
  value       = { for k, a in akamai_networklist_activations.activation : k => a.status }
}
