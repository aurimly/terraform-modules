output "cluster_names" {
  description = "Map of cluster key => cluster name (full resource name, e.g. projects/<project>/locations/<location>/clusters/<cluster_id>)."
  value       = { for k, c in google_alloydb_cluster.cluster : k => c.name }
}

output "cluster_ids" {
  description = "Map of cluster key => cluster id (projects/<project>/locations/<location>/clusters/<cluster_id>)."
  value       = { for k, c in google_alloydb_cluster.cluster : k => c.id }
}

output "cluster_states" {
  description = "Map of cluster key => current serving state of the cluster."
  value       = { for k, c in google_alloydb_cluster.cluster : k => c.state }
}

output "instance_names" {
  description = "Map of '<cluster key>/<instance key>' => instance name (full resource name)."
  value       = { for k, i in google_alloydb_instance.instance : k => i.name }
}

output "instance_ids" {
  description = "Map of '<cluster key>/<instance key>' => instance id (projects/<project>/locations/<location>/clusters/<cluster_id>/instances/<instance_id>)."
  value       = { for k, i in google_alloydb_instance.instance : k => i.id }
}

output "instance_ip_addresses" {
  description = "Map of '<cluster key>/<instance key>' => {ip_address, public_ip_address} (nulls where the IP is not enabled)."
  value = {
    for k, i in google_alloydb_instance.instance : k => {
      ip_address        = i.ip_address
      public_ip_address = i.public_ip_address
    }
  }
}

output "backup_names" {
  description = "Map of '<cluster key>/<backup key>' => backup name (full resource name)."
  value       = { for k, b in google_alloydb_backup.backup : k => b.name }
}

output "backup_ids" {
  description = "Map of '<cluster key>/<backup key>' => backup id (projects/<project>/locations/<location>/backups/<backup_id>)."
  value       = { for k, b in google_alloydb_backup.backup : k => b.id }
}

output "backup_states" {
  description = "Map of '<cluster key>/<backup key>' => current state of the backup."
  value       = { for k, b in google_alloydb_backup.backup : k => b.state }
}
