output "instance_names" {
  description = "Map of instance key => instance name."
  value       = { for k, i in google_compute_instance.instance : k => i.name }
}

output "instance_self_links" {
  description = "Map of instance key => instance self link."
  value       = { for k, i in google_compute_instance.instance : k => i.self_link }
}

output "instance_ids" {
  description = "Map of instance key => instance ID (projects/{project}/zones/{zone}/instances/{name})."
  value       = { for k, i in google_compute_instance.instance : k => i.id }
}

output "internal_ips" {
  description = "Map of instance key => list of internal IPs (one per network interface)."
  value       = { for k, i in google_compute_instance.instance : k => i.network_interface[*].network_ip }
}

output "external_ips" {
  description = "Map of instance key => list of external IPv4 addresses from access_config (empty when no interface has one)."
  value       = { for k, i in google_compute_instance.instance : k => flatten([for n in i.network_interface : [for a in n.access_config : a.nat_ip]]) }
}

output "disk_names" {
  description = "Map of instance key => list of created additional-disk names (empty when the entry has no disks)."
  value       = { for k, i in var.instances : k => [for dkey, d in local.disks : d.name if d.instance_key == k] }
}
