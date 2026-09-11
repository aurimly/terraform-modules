output "secret_names" {
  description = "Map of secret key => secret ID (name within the project)."
  value       = { for k, s in google_secret_manager_secret.secret : k => s.secret_id }
}

output "secret_ids" {
  description = "Map of secret key => secret resource name (projects/{project}/secrets/{secret_id})."
  value       = { for k, s in google_secret_manager_secret.secret : k => s.name }
}

output "secret_version_names" {
  description = "Map of version composite key (secret key/version key) => version resource name (projects/{project}/secrets/{secret_id}/versions/{version})."
  value       = { for k, v in google_secret_manager_secret_version.version : k => v.name }
}

output "iam_binding_roles" {
  description = "Map of IAM binding composite key (secret key/binding key) => role."
  value       = { for k, b in google_secret_manager_secret_iam_binding.binding : k => b.role }
}
