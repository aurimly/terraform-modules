output "secret_names" {
  description = "Map of secret key => secret name."
  value       = { for key, s in github_actions_organization_secret.secret : key => s.secret_name }
}

output "secret_updated_ats" {
  description = "Map of secret key => timestamp the provider last applied the secret value (import-only secrets show the import time — values are not readable back)."
  value       = { for key, s in github_actions_organization_secret.secret : key => s.updated_at }
}
