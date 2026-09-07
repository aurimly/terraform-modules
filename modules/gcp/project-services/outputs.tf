output "service_ids" {
  description = "Map of service key => resource id ({project_id}/{service})."
  value       = { for k, s in google_project_service.service : k => s.id }
}
