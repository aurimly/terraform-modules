output "repository_arns" {
  description = "Map of repository key => repository ARN."
  value       = { for k, r in aws_ecr_repository.repository : k => r.arn }
}

output "repository_urls" {
  description = "Map of repository key => repository URL (the registry endpoint to docker/tofu push and pull against)."
  value       = { for k, r in aws_ecr_repository.repository : k => r.repository_url }
}

output "repository_names" {
  description = "Map of repository key => repository name (the input name)."
  value       = { for k, r in aws_ecr_repository.repository : k => r.name }
}

output "registry_ids" {
  description = "Map of repository key => registry ID (the account ID owning it)."
  value       = { for k, r in aws_ecr_repository.repository : k => r.registry_id }
}
