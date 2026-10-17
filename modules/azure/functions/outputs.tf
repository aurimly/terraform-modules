output "service_plan_ids" {
  description = "Map of plan key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/serverFarms/<name>\")."
  value       = { for key, p in azurerm_service_plan.service_plan : key => p.id }
}

output "service_plan_names" {
  description = "Map of plan key => service plan name. Pass to other resources — the ARM provider name is serverFarms."
  value       = { for key, p in azurerm_service_plan.service_plan : key => p.name }
}

output "linux_function_app_ids" {
  description = "Map of app key => full ARM resource ID (\"/.../Microsoft.Web/sites/<name>\")."
  value       = { for key, a in azurerm_linux_function_app.linux_function_app : key => a.id }
}

output "linux_function_app_names" {
  description = "Map of app key => app name."
  value       = { for key, a in azurerm_linux_function_app.linux_function_app : key => a.name }
}

output "linux_function_app_default_hostnames" {
  description = "Map of app key => default hostname (<name>.azurewebsites.net) — the HTTPS entry point for HTTP-triggered functions."
  value       = { for key, a in azurerm_linux_function_app.linux_function_app : key => a.default_hostname }
}

output "linux_function_app_outbound_ip_addresses" {
  description = "Map of app key => egress IP address list — what downstream allow-lists must accept for the app's outbound calls."
  value       = { for key, a in azurerm_linux_function_app.linux_function_app : key => a.outbound_ip_address_list }
}

output "linux_function_app_identity_principal_ids" {
  description = "Map of app key => system-assigned identity principal ID, null for apps without one (user-assigned-only identities have no app-scoped principal)."
  value       = { for key, a in azurerm_linux_function_app.linux_function_app : key => length(a.identity) > 0 ? a.identity[0].principal_id : null }
}

output "linux_function_app_host_keys" {
  description = "Map of app key => { default_function_key, primary_key } read via the azurerm_function_app_host_keys data source — live keys for the app's function host. Marked sensitive: keys land in state; treat state access as key access."
  value = {
    for key, app in azurerm_linux_function_app.linux_function_app : key => {
      default_function_key = data.azurerm_function_app_host_keys.host_keys["linux.${key}"].default_function_key
      primary_key          = data.azurerm_function_app_host_keys.host_keys["linux.${key}"].primary_key
    }
  }
  sensitive = true
}

output "linux_function_app_custom_domain_verification_ids" {
  description = "Map of app key => custom domain verification ID — add it as a TXT record (asuid.<domain>) via azure/dns-records to steward a custom domain. Marked sensitive: the ID is unique per app and treated as a secret by the provider."
  value       = { for key, a in azurerm_linux_function_app.linux_function_app : key => a.custom_domain_verification_id }
  sensitive   = true
}

output "windows_function_app_ids" {
  description = "Map of app key => full ARM resource ID (\"/.../Microsoft.Web/sites/<name>\")."
  value       = { for key, a in azurerm_windows_function_app.windows_function_app : key => a.id }
}

output "windows_function_app_names" {
  description = "Map of app key => app name."
  value       = { for key, a in azurerm_windows_function_app.windows_function_app : key => a.name }
}

output "windows_function_app_default_hostnames" {
  description = "Map of app key => default hostname (<name>.azurewebsites.net) — the HTTPS entry point for HTTP-triggered functions."
  value       = { for key, a in azurerm_windows_function_app.windows_function_app : key => a.default_hostname }
}

output "windows_function_app_outbound_ip_addresses" {
  description = "Map of app key => egress IP address list — what downstream allow-lists must accept for the app's outbound calls."
  value       = { for key, a in azurerm_windows_function_app.windows_function_app : key => a.outbound_ip_address_list }
}

output "windows_function_app_identity_principal_ids" {
  description = "Map of app key => system-assigned identity principal ID, null for apps without one (user-assigned-only identities have no app-scoped principal)."
  value       = { for key, a in azurerm_windows_function_app.windows_function_app : key => length(a.identity) > 0 ? a.identity[0].principal_id : null }
}

output "windows_function_app_host_keys" {
  description = "Map of app key => { default_function_key, primary_key } read via the azurerm_function_app_host_keys data source — live keys for the app's function host. Marked sensitive: keys land in state; treat state access as key access."
  value = {
    for key, app in azurerm_windows_function_app.windows_function_app : key => {
      default_function_key = data.azurerm_function_app_host_keys.host_keys["windows.${key}"].default_function_key
      primary_key          = data.azurerm_function_app_host_keys.host_keys["windows.${key}"].primary_key
    }
  }
  sensitive = true
}

output "windows_function_app_custom_domain_verification_ids" {
  description = "Map of app key => custom domain verification ID — add it as a TXT record (asuid.<domain>) via azure/dns-records to steward a custom domain. Marked sensitive: the ID is unique per app and treated as a secret by the provider."
  value       = { for key, a in azurerm_windows_function_app.windows_function_app : key => a.custom_domain_verification_id }
  sensitive   = true
}
