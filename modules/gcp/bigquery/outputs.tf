output "dataset_ids" {
  description = "Map of dataset key => fully-qualified dataset ID (projects/{project}/datasets/{dataset_id})."
  value       = { for k, d in google_bigquery_dataset.dataset : k => d.id }
}

output "dataset_self_links" {
  description = "Map of dataset key => dataset self link."
  value       = { for k, d in google_bigquery_dataset.dataset : k => d.self_link }
}

output "table_ids" {
  description = "Map of table composite key (dataset key/table key) => fully-qualified table ID (projects/{project}/datasets/{dataset_id}/tables/{table_id})."
  value       = { for k, t in google_bigquery_table.table : k => t.id }
}

output "table_self_links" {
  description = "Map of table composite key (dataset key/table key) => table self link."
  value       = { for k, t in google_bigquery_table.table : k => t.self_link }
}

output "dataset_iam_binding_roles" {
  description = "Map of dataset IAM binding composite key (dataset key/binding key) => role."
  value       = { for k, b in google_bigquery_dataset_iam_binding.binding : k => b.role }
}
