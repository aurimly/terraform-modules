output "peering_ids" {
  description = "Map of peering key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/virtualNetworkPeerings/<name>\")."
  value       = { for k, p in azurerm_virtual_network_peering.peering : k => p.id }
}
