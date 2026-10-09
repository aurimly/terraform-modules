output "service_plan_ids" {
  description = "Map of plan key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Web/serverFarms/<name>\")."
  value       = { for key, p in azurerm_service_plan.service_plan : key => p.id }
}

output "service_plan_names" {
  description = "Map of plan key => service plan name. Pass to other resources — the ARM provider name is serverFarms."
  value       = { for key, p in azurerm_service_plan.service_plan : key => p.name }
}

output "linux_web_app_ids" {
  description = "Map of app key => full ARM resource ID (\"/.../Microsoft.Web/sites/<name>\")."
  value       = { for key, a in azurerm_linux_web_app.linux_web_app : key => a.id }
}

output "linux_web_app_names" {
  description = "Map of app key => app name."
  value       = { for key, a in azurerm_linux_web_app.linux_web_app : key => a.name }
}

output "linux_web_app_default_hostnames" {
  description = "Map of app key => default hostname (<name>.azurewebsites.net)."
  value       = { for key, a in azurerm_linux_web_app.linux_web_app : key => a.default_hostname }
}

output "linux_web_app_outbound_ip_addresses" {
  description = "Map of app key => egress IP address list of the app (the plan's outbound addresses)."
  value       = { for key, a in azurerm_linux_web_app.linux_web_app : key => a.outbound_ip_address_list }
}

output "linux_web_app_identity_principal_ids" {
  description = "Map of app key => system-assigned identity principal ID, null for apps without one."
  value       = { for key, a in azurerm_linux_web_app.linux_web_app : key => length(a.identity) > 0 ? a.identity[0].principal_id : null }
}

output "linux_web_app_custom_domain_verification_ids" {
  description = "Map of app key => custom domain verification ID — add it as a TXT record (asuid.<domain>) via azure/dns-records to steward a custom domain. Marked sensitive: the ID is unique per app and treated as a secret by the provider."
  value       = { for key, a in azurerm_linux_web_app.linux_web_app : key => a.custom_domain_verification_id }
  sensitive   = true
}

output "linux_web_app_slot_ids" {
  description = "Map of \"<app_key>.<slot_key>\" => full ARM resource ID (\"/.../Microsoft.Web/sites/<app-name>/slots/<slot-name>\")."
  value       = { for key, s in azurerm_linux_web_app_slot.linux_slot : key => s.id }
}

output "linux_web_app_slot_default_hostnames" {
  description = "Map of \"<app_key>.<slot_key>\" => slot default hostname (<app-name>-<slot-name>.azurewebsites.net)."
  value       = { for key, s in azurerm_linux_web_app_slot.linux_slot : key => s.default_hostname }
}

output "windows_web_app_ids" {
  description = "Map of app key => full ARM resource ID (\"/.../Microsoft.Web/sites/<name>\")."
  value       = { for key, a in azurerm_windows_web_app.windows_web_app : key => a.id }
}

output "windows_web_app_names" {
  description = "Map of app key => app name."
  value       = { for key, a in azurerm_windows_web_app.windows_web_app : key => a.name }
}

output "windows_web_app_default_hostnames" {
  description = "Map of app key => default hostname (<name>.azurewebsites.net)."
  value       = { for key, a in azurerm_windows_web_app.windows_web_app : key => a.default_hostname }
}

output "windows_web_app_outbound_ip_addresses" {
  description = "Map of app key => egress IP address list of the app (the plan's outbound addresses)."
  value       = { for key, a in azurerm_windows_web_app.windows_web_app : key => a.outbound_ip_address_list }
}

output "windows_web_app_identity_principal_ids" {
  description = "Map of app key => system-assigned identity principal ID, null for apps without one."
  value       = { for key, a in azurerm_windows_web_app.windows_web_app : key => length(a.identity) > 0 ? a.identity[0].principal_id : null }
}

output "windows_web_app_custom_domain_verification_ids" {
  description = "Map of app key => custom domain verification ID — add it as a TXT record (asuid.<domain>) via azure/dns-records to steward a custom domain. Marked sensitive: the ID is unique per app and treated as a secret by the provider."
  value       = { for key, a in azurerm_windows_web_app.windows_web_app : key => a.custom_domain_verification_id }
  sensitive   = true
}

output "windows_web_app_slot_ids" {
  description = "Map of \"<app_key>.<slot_key>\" => full ARM resource ID (\"/.../Microsoft.Web/sites/<app-name>/slots/<slot-name>\")."
  value       = { for key, s in azurerm_windows_web_app_slot.windows_slot : key => s.id }
}

output "windows_web_app_slot_default_hostnames" {
  description = "Map of \"<app_key>.<slot_key>\" => slot default hostname (<app-name>-<slot-name>.azurewebsites.net)."
  value       = { for key, s in azurerm_windows_web_app_slot.windows_slot : key => s.default_hostname }
}
