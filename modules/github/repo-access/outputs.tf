output "collaborator_ids" {
  description = "Map of repo key => resource ID (numeric repository ID as a string)."
  value       = { for k, c in github_repository_collaborators.collaborators : k => c.id }
}

output "invitation_ids" {
  description = "Map of repo key => map of username => pending collaborator invitation ID (empty once all invitations are accepted)."
  value       = { for k, c in github_repository_collaborators.collaborators : k => c.invitation_ids }
}
