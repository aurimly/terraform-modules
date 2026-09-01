output "role_assignments" {
  description = "Map of role assignment key => assignment ID (\"{resource_id},{role},{subject}\"), also usable as the import ID."
  value       = { for k, ra in stackit_authorization_folder_role_assignment.folder_role_assignment : k => ra.id }
}
