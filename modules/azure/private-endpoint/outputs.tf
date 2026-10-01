output "private_endpoint_ids" {
  description = "Map of key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/privateEndpoints/<name>\")."
  value       = { for k, e in azurerm_private_endpoint.endpoint : k => e.id }
}

output "private_endpoint_names" {
  description = "Map of key => private endpoint name."
  value       = { for k, e in azurerm_private_endpoint.endpoint : k => e.name }
}

output "private_endpoint_network_interface_ids" {
  description = "Map of key => ARM ID of the network interface attached to the private endpoint — useful for wiring NSGs to private endpoint traffic."
  value       = { for k, e in azurerm_private_endpoint.endpoint : k => e.network_interface[0].id }
}

output "private_endpoint_custom_dns_configs" {
  description = "Map of key => { fqdn, ip_addresses } — populated when no private DNS zone group is attached (BYO DNS setups); empty when a zone group is connected correctly."
  value = {
    for k, e in azurerm_private_endpoint.endpoint : k => {
      fqdn         = try(e.custom_dns_configs[0].fqdn, null)
      ip_addresses = try(e.custom_dns_configs[0].ip_addresses, [])
    }
  }
}

output "private_ip_addresses" {
  description = "Map of key => private IP address assigned to the endpoint from its subnet."
  value       = { for k, e in azurerm_private_endpoint.endpoint : k => e.private_service_connection[0].private_ip_address }
}

output "private_dns_zone_ids" {
  description = "Map of zone key => full ARM ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<name>\") for the zones created via private_dns_zones — feeds private_dns_zone_group.private_dns_zone_ids or AKS private_dns_zone_id."
  value       = { for k, z in azurerm_private_dns_zone.private_dns_zone : k => z.id }
}

output "private_dns_zone_names" {
  description = "Map of zone key => zone name."
  value       = { for k, z in azurerm_private_dns_zone.private_dns_zone : k => z.name }
}

output "virtual_network_link_ids" {
  description = "Map of \"<zone_key>.<link_key>\" => full ARM ID of the private DNS zone virtual network link."
  value       = { for k, l in azurerm_private_dns_zone_virtual_network_link.link : k => l.id }
}
