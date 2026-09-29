output "managed_identity_ids" {
  description = "Map of managed identity key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<name>\")."
  value       = { for k, i in azurerm_user_assigned_identity.managed_identity : k => i.id }
}

output "managed_identity_principal_ids" {
  description = "Map of managed identity key => principal ID — the service-principal object ID used for RBAC role assignments."
  value       = { for k, i in azurerm_user_assigned_identity.managed_identity : k => i.principal_id }
}

output "managed_identity_client_ids" {
  description = "Map of managed identity key => client ID — the app (client) ID used for Entra ID / SDK authentication and federated credentials."
  value       = { for k, i in azurerm_user_assigned_identity.managed_identity : k => i.client_id }
}

output "managed_identity_tenant_ids" {
  description = "Map of managed identity key => tenant ID the identity belongs to."
  value       = { for k, i in azurerm_user_assigned_identity.managed_identity : k => i.tenant_id }
}
