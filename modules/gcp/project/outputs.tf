output "project_ids" {
  description = "Map of project key => project ID (the user-defined project_id string)."
  value       = { for k, p in google_project.project : k => p.project_id }
}

output "project_numbers" {
  description = "Map of project key => project number (GCP-generated numeric ID)."
  value       = { for k, p in google_project.project : k => p.number }
}

output "project_names" {
  description = "Map of project key => project name."
  value       = { for k, p in google_project.project : k => p.name }
}
