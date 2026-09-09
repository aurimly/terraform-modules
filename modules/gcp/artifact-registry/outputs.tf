output "repository_ids" {
  description = "Map of repository key => repository_id."
  value       = { for k, r in google_artifact_registry_repository.repository : k => r.repository_id }
}

output "repository_uris" {
  description = "Map of repository key => registry URI (host/project/repository_id)."
  value       = { for k, r in google_artifact_registry_repository.repository : k => r.registry_uri }
}

output "repository_names" {
  description = "Map of repository key => fully-qualified repository name (projects/.../locations/.../repositories/...)."
  value       = { for k, r in google_artifact_registry_repository.repository : k => r.id }
}

output "iam_binding_roles" {
  description = "Map of IAM binding composite key (repository key/binding key) => role."
  value       = { for k, b in google_artifact_registry_repository_iam_binding.binding : k => b.role }
}
