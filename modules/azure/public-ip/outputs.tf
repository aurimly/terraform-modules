output "public_ip_ids" {
  description = "Map of public IP key => full ARM resource ID (\"/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>\")."
  value       = { for k, p in azurerm_public_ip.public_ip : k => p.id }
}

output "public_ip_addresses" {
  description = "Map of public IP key => the assigned IP address, null for addresses not yet associated — Dynamic allocation only assigns an address once the IP is attached to a resource. Covers all keys."
  value       = { for k, p in azurerm_public_ip.public_ip : k => p.ip_address != "" ? p.ip_address : null }
}

output "public_ip_fqdns" {
  description = "Map of public IP key => the FQDN of the DNS record Azure creates for the IP (<label>.<region>.cloudapp.azure.com), null for IPs without a domain_name_label. Covers all keys."
  value       = { for k, p in azurerm_public_ip.public_ip : k => p.fqdn != "" ? p.fqdn : null }
}
