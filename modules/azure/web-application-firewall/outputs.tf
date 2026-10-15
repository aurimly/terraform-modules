output "policy_ids" {
  description = "Map of policies key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/<name>\")."
  value       = { for key, p in azurerm_web_application_firewall_policy.policy : key => p.id }
}

output "policy_names" {
  description = "Map of policies key => policy name."
  value       = { for key, p in azurerm_web_application_firewall_policy.policy : key => p.name }
}
