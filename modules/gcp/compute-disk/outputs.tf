output "disk_names" {
  description = "Map of disk key => disk name."
  value       = { for k, d in google_compute_disk.disk : k => d.name }
}

output "disk_self_links" {
  description = "Map of disk key => self link."
  value       = { for k, d in google_compute_disk.disk : k => d.self_link }
}

output "disk_ids" {
  description = "Map of disk key => fully-qualified disk ID (projects/{project}/zones/{zone}/disks/{name})."
  value       = { for k, d in google_compute_disk.disk : k => d.id }
}

output "snapshot_names" {
  description = "Map of snapshot key => snapshot name."
  value       = { for k, s in google_compute_snapshot.snapshot : k => s.name }
}

output "snapshot_self_links" {
  description = "Map of snapshot key => self link (projects/{project}/global/snapshots/{name})."
  value       = { for k, s in google_compute_snapshot.snapshot : k => s.self_link }
}

output "snapshot_schedule_policy_names" {
  description = "Map of snapshot schedule policy key => policy name."
  value       = { for k, p in google_compute_resource_policy.snapshot_schedule : k => p.name }
}

output "snapshot_schedule_policy_self_links" {
  description = "Map of snapshot schedule policy key => self link (projects/{project}/regions/{region}/resourcePolicies/{name})."
  value       = { for k, p in google_compute_resource_policy.snapshot_schedule : k => p.self_link }
}
