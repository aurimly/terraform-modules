output "manager_names" {
  description = "Map of manager key => managed instance group name."
  value       = { for k, m in google_compute_instance_group_manager.manager : k => m.name }
}

output "manager_ids" {
  description = "Map of manager key => managed instance group ID (projects/{project}/zones/{zone}/instanceGroupManagers/{name})."
  value       = { for k, m in google_compute_instance_group_manager.manager : k => m.id }
}

output "manager_self_links" {
  description = "Map of manager key => managed instance group self link."
  value       = { for k, m in google_compute_instance_group_manager.manager : k => m.self_link }
}

output "instance_group_urls" {
  description = "Map of manager key => underlying instance group URL; the target for backend services."
  value       = { for k, m in google_compute_instance_group_manager.manager : k => m.instance_group }
}

output "autoscaler_names" {
  description = "Map of manager key => autoscaler name (only for entries with an autoscaler)."
  value       = { for k, a in google_compute_autoscaler.autoscaler : k => a.name }
}

output "autoscaler_self_links" {
  description = "Map of manager key => autoscaler self link (only for entries with an autoscaler)."
  value       = { for k, a in google_compute_autoscaler.autoscaler : k => a.self_link }
}
