output "instance_ids" {
  description = "Map of instance key => fully-qualified instance id (projects/.../locations/.../instances/...)."
  value       = { for k, i in google_filestore_instance.instance : k => i.id }
}

output "instance_ips" {
  description = "Map of instance key => IP addresses of the instance networks (the NFS mount endpoints)."
  value       = { for k, i in google_filestore_instance.instance : k => flatten([for n in i.networks : n.ip_addresses]) }
}

output "backup_ids" {
  description = "Map of composite backup key (instance key/backup key) => fully-qualified backup id."
  value       = { for k, b in google_filestore_backup.backup : k => b.id }
}
