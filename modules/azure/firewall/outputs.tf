output "firewall_ids" {
  description = "Map of firewall key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/azureFirewalls/<name>\")."
  value       = { for key, f in azurerm_firewall.firewall : key => f.id }
}

output "firewall_names" {
  description = "Map of firewall key => firewall name."
  value       = { for key, f in azurerm_firewall.firewall : key => f.name }
}

output "firewall_private_ip_addresses" {
  description = "Map of firewall key => private IP addresses per ip_configuration of a VNet firewall, empty for hub firewalls. IP addresses are empty strings until the firewall is healthy — they land only after creation completes."
  value       = { for key, f in azurerm_firewall.firewall : key => [for ipc in f.ip_configuration : ipc.private_ip_address] }
}

output "firewall_hub_private_ip_addresses" {
  description = "Map of firewall key => hub firewall address details ({ private_ip_address, public_ip_addresses } from the Virtual Hub) or null for VNet firewalls."
  value       = { for key, f in azurerm_firewall.firewall : key => length(f.virtual_hub) > 0 ? { private_ip_address = f.virtual_hub[0].private_ip_address, public_ip_addresses = f.virtual_hub[0].public_ip_addresses } : null }
}

output "firewall_policy_ids" {
  description = "Map of policy key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/firewallPolicies/<name>\")."
  value       = { for key, p in azurerm_firewall_policy.policy : key => p.id }
}

output "firewall_policy_names" {
  description = "Map of policy key => policy name."
  value       = { for key, p in azurerm_firewall_policy.policy : key => p.name }
}

output "rule_collection_group_ids" {
  description = "Map of \"<policy_key>.<group_key>\" => full ARM resource ID (\"<firewallPolicyID>/ruleCollectionGroups/<name>\")."
  value       = { for key, g in azurerm_firewall_policy_rule_collection_group.rule_collection_group : key => g.id }
}

output "public_ip_ids" {
  description = "Map of public_ip key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>\"). Covers the in-module public_ips only — firewall-side outputs for externally supplied IPs stay with the azure/public-ip module."
  value       = local.public_ip_ids
}

output "public_ip_addresses" {
  description = "Map of public_ip key => assigned address, null for addresses not yet assigned. In-module public IPs only (fqdns trimmed — firewall addresses are Standard/Static IPs without a domain label)."
  value       = { for key, pip in azurerm_public_ip.pip : key => pip.ip_address != "" ? pip.ip_address : null }
}
