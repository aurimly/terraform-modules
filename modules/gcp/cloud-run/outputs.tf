output "service_uris" {
  description = "Map of service key => service URI."
  value       = { for k, s in google_cloud_run_v2_service.service : k => s.uri }
}

output "service_names" {
  description = "Map of service key => service name."
  value       = { for k, s in google_cloud_run_v2_service.service : k => s.name }
}

output "service_latest_ready_revisions" {
  description = "Map of service key => latest ready revision name."
  value       = { for k, s in google_cloud_run_v2_service.service : k => s.latest_ready_revision }
}

output "service_ids" {
  description = "Map of service key => service id."
  value       = { for k, s in google_cloud_run_v2_service.service : k => s.id }
}

output "iam_binding_roles" {
  description = "Map of IAM binding composite key (service key/binding key) => role."
  value       = { for k, b in google_cloud_run_v2_service_iam_binding.binding : k => b.role }
}
