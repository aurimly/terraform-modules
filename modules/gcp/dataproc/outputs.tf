output "cluster_names" {
  description = "Map of cluster key => cluster name."
  value       = { for k, c in google_dataproc_cluster.cluster : k => c.name }
}

output "cluster_ids" {
  description = "Map of cluster key => fully-qualified cluster name (projects/<project>/regions/<region>/clusters/<name>). Only populated for clusters with an explicit project_id; when project_id is unset the provider-level project is used and the full name is not determinable from the module."
  value       = local.cluster_ids
}

output "cluster_effective_labels" {
  description = "Map of cluster key => effective labels (includes the goog-dataproc-cluster-name etc. labels applied by GCP)."
  value       = { for k, c in google_dataproc_cluster.cluster : k => c.effective_labels }
}

output "iam_binding_roles" {
  description = "Map of '<cluster key>/<binding key>' => role."
  value       = { for k, b in google_dataproc_cluster_iam_binding.binding : k => b.role }
}
