output "virtual_network_ids" {
  description = "Map of virtual network key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>\")."
  value       = { for k, v in azurerm_virtual_network.virtual_network : k => v.id }
}

output "virtual_network_names" {
  description = "Map of virtual network key => virtual network name. azurerm resources take virtual_network_name (a name string), not an ID — hand this to other Azure network modules."
  value       = { for k, v in azurerm_virtual_network.virtual_network : k => v.name }
}

output "virtual_network_guids" {
  description = "Map of virtual network key => unique identifier GUID assigned by Azure to the virtual network."
  value       = { for k, v in azurerm_virtual_network.virtual_network : k => v.guid }
}
