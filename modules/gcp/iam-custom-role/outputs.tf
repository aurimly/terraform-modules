output "organization_role_names" {
  description = "Map of organization role key => full role name (organizations/<org_id>/roles/<role_id>) to pass to IAM bindings."
  value       = { for k, r in google_organization_iam_custom_role.organization_role : k => r.name }
}

output "project_role_names" {
  description = "Map of project role key => full role name (projects/<project>/roles/<role_id>) to pass to IAM bindings."
  value       = { for k, r in google_project_iam_custom_role.project_role : k => r.name }
}
