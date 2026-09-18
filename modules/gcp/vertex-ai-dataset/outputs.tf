output "dataset_ids" {
  description = "Map of dataset key => dataset id (projects/{project}/locations/{region}/datasets/{name})."
  value       = { for k, d in google_vertex_ai_dataset.dataset : k => d.id }
}

output "dataset_names" {
  description = "Map of dataset key => resource name of the dataset (Google-assigned)."
  value       = { for k, d in google_vertex_ai_dataset.dataset : k => d.name }
}

output "dataset_create_times" {
  description = "Map of dataset key => creation timestamp (RFC3339 UTC \"Zulu\" format)."
  value       = { for k, d in google_vertex_ai_dataset.dataset : k => d.create_time }
}
