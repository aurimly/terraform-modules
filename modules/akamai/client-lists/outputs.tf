output "client_list_ids" {
  description = "Map of key => unique list ID (<contractId>_<NAME>), the import ID of akamai_clientlist_list."
  value       = { for k, l in akamai_clientlist_list.list : k => l.list_id }
}

output "client_list_versions" {
  description = "Map of key => list version (starts at 1, increments on every modification; wired into the activation resource)."
  value       = { for k, l in akamai_clientlist_list.list : k => l.version }
}

output "activation_statuses" {
  description = "Map of key => activation status, for entries that have an activation."
  value       = { for k, a in akamai_clientlist_activation.activation : k => a.status }
}
