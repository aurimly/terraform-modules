output "allocated_range_names" {
  description = "Map of composite key (connection key/range key) => {name, address, prefix_length} for ranges allocated by this module."
  value = {
    for k, r in google_compute_global_address.range : k => {
      name          = r.name
      address       = r.address
      prefix_length = r.prefix_length
    }
  }
}

output "reserved_peering_ranges" {
  description = "Map of connection key => distinct list of range names reserved on the connection (allocated by this module and pre-existing)."
  value       = { for k, c in google_service_networking_connection.connection : k => c.reserved_peering_ranges }
}

output "connection_peerings" {
  description = "Map of connection key => peering resource name created by the service networking connection."
  value       = { for k, c in google_service_networking_connection.connection : k => c.peering }
}
