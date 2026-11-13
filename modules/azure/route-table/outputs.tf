output "route_table_ids" {
  description = "Map of route table key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<name>\")."
  value       = { for k, v in azurerm_route_table.route_table : k => v.id }
}

output "route_table_names" {
  description = "Map of route table key => route table name. azurerm resources take route_table_name (a name string), not an ID — hand this to other Azure network modules."
  value       = { for k, v in azurerm_route_table.route_table : k => v.name }
}

output "route_ids" {
  description = "Map of \"<route-table-key>.<route-key>\" => full ARM route resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<table-name>/routes/<route-name>\")."
  value       = { for k, v in azurerm_route.route : k => v.id }
}

output "route_names" {
  description = "Map of \"<route-table-key>.<route-key>\" => route name."
  value       = { for k, v in azurerm_route.route : k => v.name }
}
