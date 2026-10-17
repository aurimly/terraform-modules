output "repository_webhook_urls" {
  description = "Map of webhook key => payload URL. Marked sensitive: GitHub may fold basic-auth credentials into the URL and the provider marks it sensitive."
  value       = { for key, hook in github_repository_webhook.repository_webhook : key => hook.url }
  sensitive   = true
}

output "repository_webhook_ids" {
  description = "Map of webhook key => numeric hook ID as encoded by the resource (\"<repository>/<id>\") — the import address and the hook API target."
  value       = { for key, hook in github_repository_webhook.repository_webhook : key => hook.id }
}

output "repository_webhook_repositories" {
  description = "Map of webhook key => repository name the webhook is pinned to."
  value       = { for key, hook in github_repository_webhook.repository_webhook : key => hook.repository }
}

output "organization_webhook_urls" {
  description = "Map of webhook key => payload URL. Marked sensitive: the provider marks the organization webhook URL sensitive."
  value       = { for key, hook in github_organization_webhook.organization_webhook : key => hook.url }
  sensitive   = true
}

output "organization_webhook_ids" {
  description = "Map of webhook key => numeric hook ID — the import address and the hook API target."
  value       = { for key, hook in github_organization_webhook.organization_webhook : key => hook.id }
}
