output "registry_ids" {
  description = "Map of registry key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<name>\")."
  value       = { for key, registry in azurerm_container_registry.registry : key => registry.id }
}

output "registry_names" {
  description = "Map of registry key => registry name."
  value       = { for key, registry in azurerm_container_registry.registry : key => registry.name }
}

output "registry_login_servers" {
  description = "Map of registry key => the registry login server (\"<name>.azurecr.io\")."
  value       = { for key, registry in azurerm_container_registry.registry : key => registry.login_server }
}

output "registry_admin_usernames" {
  description = "Map of registry key => admin username — only when admin_enabled (null otherwise)."
  value       = { for key, registry in azurerm_container_registry.registry : key => registry.admin_username }
}

output "registry_admin_passwords" {
  description = "Map of registry key => admin password — only when admin_enabled (sensitive; see Notes)."
  value       = { for key, registry in azurerm_container_registry.registry : key => registry.admin_password }
  sensitive   = true
}

output "registry_identity_principal_ids" {
  description = "Map of registry key => the system-assigned identity principal ID (identity blocks only — null otherwise)."
  value       = { for key, registry in azurerm_container_registry.registry : key => try(registry.identity[0].principal_id, null) }
}

output "data_endpoint_host_names" {
  description = "Map of registry key => set of dedicated data-endpoint host names (data_endpoint_enabled only)."
  value       = { for key, registry in azurerm_container_registry.registry : key => registry.data_endpoint_host_names }
}

output "webhook_ids" {
  description = "Map of \"<registry_key>.<webhook_key>\" => full ARM resource ID of the webhook."
  value       = { for key, webhook in azurerm_container_registry_webhook.webhook : key => webhook.id }
}

output "scope_map_ids" {
  description = "Map of \"<registry_key>.<scope_map_key>\" => full ARM resource ID of the scope map."
  value       = { for key, scope_map in azurerm_container_registry_scope_map.scope_map : key => scope_map.id }
}

output "token_ids" {
  description = "Map of \"<registry_key>.<token_key>\" => full ARM resource ID of the token."
  value       = { for key, token in azurerm_container_registry_token.token : key => token.id }
}

output "token_password_values" {
  description = "Map of \"<registry_key>.<token_key>\" => { password1, password2 } — the generated token passwords (sensitive; see Notes)."
  value = {
    for key, password in azurerm_container_registry_token_password.password : key => {
      password1 = tolist(password.password1)[0].value
      password2 = try(tolist(password.password2)[0].value, null)
    }
  }
  sensitive = true
}
