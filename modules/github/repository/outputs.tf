output "repo_full_names" {
  description = "Map of repo key => full name (owner/name)."
  value       = { for k, r in github_repository.repo : k => r.full_name }
}

output "repo_ids" {
  description = "Map of repo key => GitHub node ID (used as repository_id for branch protection)."
  value       = { for k, r in github_repository.repo : k => r.node_id }
}

output "repo_names" {
  description = "Map of repo key => repo name."
  value       = { for k, r in github_repository.repo : k => r.name }
}

output "default_branch" {
  description = "Map of repo key => default branch (computed; the input does not set it)."
  value       = { for k, r in github_repository.repo : k => r.default_branch }
}

output "ssh_clone_urls" {
  description = "Map of repo key => SSH clone URL."
  value       = { for k, r in github_repository.repo : k => r.ssh_clone_url }
}

output "html_urls" {
  description = "Map of repo key => HTML URL."
  value       = { for k, r in github_repository.repo : k => r.html_url }
}
