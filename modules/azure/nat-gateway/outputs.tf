output "nat_gateway_ids" {
  description = "Map of key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/natGateways/<name>\")."
  value       = { for k, gw in azurerm_nat_gateway.nat_gateway : k => gw.id }
}

output "nat_gateway_names" {
  description = "Map of key => NAT gateway name."
  value       = { for k, gw in azurerm_nat_gateway.nat_gateway : k => gw.name }
}

output "nat_gateway_resource_guids" {
  description = "Map of key => Azure resource GUID of the NAT gateway."
  value       = { for k, gw in azurerm_nat_gateway.nat_gateway : k => gw.resource_guid }
}

output "public_ip_association_ids" {
  description = "Map of \"<gateway_key>.pip<index>\" => association ID. The association ID is Terraform-specific (\"<natGatewayID>|<publicIPAddressID>\") and only exposed for import/bookkeeping."
  value       = { for k, a in azurerm_nat_gateway_public_ip_association.public_ip : k => a.id }
}

output "public_ip_prefix_association_ids" {
  description = "Map of \"<gateway_key>.prefix<index>\" => association ID. The association ID is Terraform-specific (\"<natGatewayID>|<publicIPPrefixID>\") and only exposed for import/bookkeeping."
  value       = { for k, a in azurerm_nat_gateway_public_ip_prefix_association.public_ip_prefix : k => a.id }
}
