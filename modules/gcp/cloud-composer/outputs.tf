output "environment_names" {
  description = "Map of environment key => environment name."
  value       = { for k, e in google_composer_environment.environment : k => e.name }
}

output "environment_ids" {
  description = "Map of environment key => environment id (projects/<project>/locations/<region>/environments/<name>)."
  value       = { for k, e in google_composer_environment.environment : k => e.id }
}

output "environment_urls" {
  description = "Map of environment key => Airflow web UI URI (null where config is unset; populated by the API after creation)."
  value       = { for k, e in google_composer_environment.environment : k => length(e.config) > 0 ? e.config.0.airflow_uri : null }
}

output "dag_gcs_prefixes" {
  description = "Map of environment key => GCS prefix where DAGs are uploaded (null where config is unset). Note: the provider exposes no bucket attribute; this prefix identifies the environment bucket."
  value       = { for k, e in google_composer_environment.environment : k => length(e.config) > 0 ? e.config.0.dag_gcs_prefix : null }
}

output "gke_clusters" {
  description = "Map of environment key => name of the GKE cluster serving the environment (null where config is unset)."
  value       = { for k, e in google_composer_environment.environment : k => length(e.config) > 0 ? e.config.0.gke_cluster : null }
}
