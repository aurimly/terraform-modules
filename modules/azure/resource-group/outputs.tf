output "resource_group_ids" {
  description = "Map of resource group key => resource group ID (\"/subscriptions/<subscription-id>/resourceGroups/<name>\")."
  value       = { for k, rg in azurerm_resource_group.resource_group : k => rg.id }
}

output "resource_group_names" {
  description = "Map of resource group key => resource group name. azurerm resources take resource_group_name, not an ID — hand this to other Azure resource modules."
  value       = { for k, rg in azurerm_resource_group.resource_group : k => rg.name }
}
