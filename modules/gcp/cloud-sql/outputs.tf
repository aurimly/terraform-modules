output "instance_names" {
  description = "Map of instance key => instance name."
  value       = { for k, i in google_sql_database_instance.instance : k => i.name }
}

output "instance_connection_names" {
  description = "Map of instance key => connection name (project:region:instance) used by Cloud Run, GKE and App Engine connectors."
  value       = { for k, i in google_sql_database_instance.instance : k => i.connection_name }
}

output "instance_self_links" {
  description = "Map of instance key => instance self link."
  value       = { for k, i in google_sql_database_instance.instance : k => i.self_link }
}

output "instance_ip_addresses" {
  description = "Map of instance key => {first_ip_address, private_ip_address, public_ip_address} (nulls where the IP is not enabled; private IP requires Private Services Access)."
  value = {
    for k, i in google_sql_database_instance.instance : k => {
      first_ip_address   = i.first_ip_address
      private_ip_address = i.private_ip_address
      public_ip_address  = i.public_ip_address
    }
  }
}

output "replica_names" {
  description = "Map of '<instance key>/<replica key>' => replica instance name."
  value       = { for k, r in google_sql_database_instance.replica : k => r.name }
}

output "replica_connection_names" {
  description = "Map of '<instance key>/<replica key>' => replica connection name (project:region:instance)."
  value       = { for k, r in google_sql_database_instance.replica : k => r.connection_name }
}
