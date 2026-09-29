output "subnet_ids" {
  description = "Map of subnet key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<name>\")."
  value       = { for k, s in azurerm_subnet.subnet : k => s.id }
}

output "subnet_names" {
  description = "Map of subnet key => subnet name."
  value       = { for k, s in azurerm_subnet.subnet : k => s.name }
}

output "subnet_address_prefixes" {
  description = "Map of subnet key => list of configured address prefixes (IPv4 and/or IPv6 CIDRs) — handy for wiring NSG rules or firewall sources in the consumer."
  value       = { for k, s in azurerm_subnet.subnet : k => s.address_prefixes }
}
