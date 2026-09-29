output "network_security_group_ids" {
  description = "Map of network security group key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<name>\")."
  value       = { for k, g in azurerm_network_security_group.network_security_group : k => g.id }
}

output "network_security_group_names" {
  description = "Map of network security group key => network security group name. azurerm resources take network_security_group_name (a name string), not an ID — hand this to other Azure network modules."
  value       = { for k, g in azurerm_network_security_group.network_security_group : k => g.name }
}

output "security_rule_ids" {
  description = "Map of composed rule key \"<group-key>.<rule-key>\" => full ARM resource ID of the azurerm_network_security_rule (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<nsg>/securityRules/<rule-name>\")."
  value       = { for k, r in azurerm_network_security_rule.security_rule : k => r.id }
}
