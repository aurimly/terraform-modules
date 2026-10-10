output "secret_names" {
  description = "Map of secret key => secret name."
  value       = { for k, s in github_actions_secret.secret : k => s.secret_name }
}
