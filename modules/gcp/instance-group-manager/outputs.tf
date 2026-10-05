output "manager_names" {
  description = "Map of manager key => managed instance group name."
  value = merge(
    { for k, m in google_compute_instance_group_manager.manager : k => m.name },
    { for k, m in google_compute_region_instance_group_manager.regional_manager : k => m.name },
  )
}

output "manager_ids" {
  description = "Map of manager key => managed instance group ID (zonal: projects/{project}/zones/{zone}/instanceGroupManagers/{name}; regional: projects/{project}/regions/{region}/instanceGroupManagers/{name})."
  value = merge(
    { for k, m in google_compute_instance_group_manager.manager : k => m.id },
    { for k, m in google_compute_region_instance_group_manager.regional_manager : k => m.id },
  )
}

output "manager_self_links" {
  description = "Map of manager key => managed instance group self link."
  value = merge(
    { for k, m in google_compute_instance_group_manager.manager : k => m.self_link },
    { for k, m in google_compute_region_instance_group_manager.regional_manager : k => m.self_link },
  )
}

output "instance_group_urls" {
  description = "Map of manager key => underlying instance group URL; the target for backend services (zonal and regional instance group URLs respectively)."
  value = merge(
    { for k, m in google_compute_instance_group_manager.manager : k => m.instance_group },
    { for k, m in google_compute_region_instance_group_manager.regional_manager : k => m.instance_group },
  )
}

output "autoscaler_names" {
  description = "Map of manager key => autoscaler name (only for entries with an autoscaler)."
  value = merge(
    { for k, a in google_compute_autoscaler.autoscaler : k => a.name },
    { for k, a in google_compute_region_autoscaler.regional_autoscaler : k => a.name },
  )
}

output "autoscaler_self_links" {
  description = "Map of manager key => autoscaler self link (only for entries with an autoscaler)."
  value = merge(
    { for k, a in google_compute_autoscaler.autoscaler : k => a.self_link },
    { for k, a in google_compute_region_autoscaler.regional_autoscaler : k => a.self_link },
  )
}
