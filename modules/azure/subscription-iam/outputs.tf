output "role_assignment_ids" {
  description = "Map of role assignment key => role assignment resource ID (\"/subscriptions/<id>/providers/Microsoft.Authorization/roleAssignments/<assignment-guid>\")."
  value       = { for k, r in azurerm_role_assignment.role_assignment : k => r.id }
}
