output "instance_ids" {
  description = "Map of instance key => full resource path (projects/<project>/locations/<location>/instances/<name>)."
  value       = { for k, i in google_memorystore_instance.instance : k => i.id }
}

output "instance_endpoints" {
  description = "Map of instance key => list of auto-created PSC endpoints ({ip_address, port, connection_type}); empty when no endpoints exist."
  value = {
    for k, i in google_memorystore_instance.instance : k => flatten([
      for ep in try(i.endpoints, []) : [
        for c in try(ep.connections, []) : [
          for psc in try(c.psc_auto_connection, []) : {
            ip_address      = psc.ip_address
            port            = psc.port
            connection_type = psc.connection_type
          }
        ]
      ]
    ])
  }
}

output "instance_states" {
  description = "Map of instance key => current state (CREATING, ACTIVE, UPDATING or DELETING)."
  value       = { for k, i in google_memorystore_instance.instance : k => i.state }
}

output "instance_uids" {
  description = "Map of instance key => system-assigned unique identifier."
  value       = { for k, i in google_memorystore_instance.instance : k => i.uid }
}
