output "app_ids" {
  description = "Map of app key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.App/containerApps/<name>\")."
  value       = { for key, app in azurerm_container_app.container_app : key => app.id }
}

output "app_names" {
  description = "Map of app key => app name."
  value       = { for key, app in azurerm_container_app.container_app : key => app.name }
}

output "app_latest_revision_fqdns" {
  description = "Map of app key => the FQDN of the latest revision — the URL to hit when ingress is external. Apps without ingress return an empty string."
  value       = { for key, app in azurerm_container_app.container_app : key => app.latest_revision_fqdn }
}

output "app_latest_revision_names" {
  description = "Map of app key => the name of the latest revision — useful for finding revision-specific logs and split-traffic targets."
  value       = { for key, app in azurerm_container_app.container_app : key => app.latest_revision_name }
}

output "app_outbound_ip_addresses" {
  description = "Map of app key => the list of outbound IP addresses of the app — the egress addresses downstream services must allow-list."
  value       = { for key, app in azurerm_container_app.container_app : key => app.outbound_ip_addresses }
}

output "app_custom_domain_verification_ids" {
  description = "Map of app key => the custom-domain verification ID — the value of the `asuid.<custom-domain>` TXT record required before binding a custom domain to the app. Sensitive: the provider marks the source attribute sensitive; it lands in state and anyone with state access can read it."
  value       = { for key, app in azurerm_container_app.container_app : key => app.custom_domain_verification_id }
  sensitive   = true
}

output "app_identity_principal_ids" {
  description = "Map of app key => the system-assigned principal ID of the app's identity — null when the app has no identity or a user-assigned only one."
  value = {
    for key, app in azurerm_container_app.container_app :
    key => try(app.identity[0].principal_id, null)
  }
}
