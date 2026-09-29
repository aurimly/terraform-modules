output "network_interface_ids" {
  description = "Map of network interface key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/networkInterfaces/<name>\")."
  value       = { for k, n in azurerm_network_interface.network_interface : k => n.id }
}

output "network_interface_names" {
  description = "Map of network interface key => network interface name."
  value       = { for k, n in azurerm_network_interface.network_interface : k => n.name }
}

output "network_interface_private_ips" {
  description = "Map of network interface key => list of private IP addresses across the NIC's IP configurations (from the provider's computed private_ip_addresses) — a NIC can carry several; consumers wanting \"the\" IP take the primary's."
  value       = { for k, n in azurerm_network_interface.network_interface : k => n.private_ip_addresses }
}
