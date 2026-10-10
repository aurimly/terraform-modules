output "environment_names" {
  description = "Map of environment key => environment name (used by consumers that wire deployments against the name)."
  value       = { for k, e in github_repository_environment.env : k => e.environment }
}

output "environment_import_ids" {
  description = "Map of environment key => resource ID (<repository>:<environment name, ':' escaped as ?? >, usable directly for import)."
  value       = { for k, e in github_repository_environment.env : k => e.id }
}

output "secret_names" {
  description = "Map of environment-scoped secret key (\"<env_key>:<secret_key>\") => secret name."
  value       = { for k, s in github_actions_environment_secret.env_secret : k => s.secret_name }
}

output "variable_names" {
  description = "Map of environment-scoped variable key (\"<env_key>:<variable_key>\") => variable name."
  value       = { for k, v in github_actions_environment_variable.env_variable : k => v.variable_name }
}
