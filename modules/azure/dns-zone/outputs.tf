output "zone_ids" {
  description = "Map of zone key => full ARM resource ID for both zone kinds (public zones under providers/Microsoft.Network/dnsZones, private under Microsoft.Network/privateDnsZones). Use as private_dns_zone_id for private zones in the azure/dns-records module."
  value = merge(
    { for key, zone in azurerm_dns_zone.zone : key => zone.id },
    { for key, zone in azurerm_private_dns_zone.zone : key => zone.id }
  )
}

output "zone_names" {
  description = "Map of zone key => zone name — the FQDN value of the Microsoft.Network/dnsZones or privateDnsZones id, e.g. \"example.com\"; what the azure/dns-records module takes as zone_name for public zones."
  value = merge(
    { for key, zone in azurerm_dns_zone.zone : key => zone.name },
    { for key, zone in azurerm_private_dns_zone.zone : key => zone.name }
  )
}

output "zone_name_servers" {
  description = "Map of zone key => list of Azure-assigned authoritative name servers for public zones — what the NS records at the registrar get pointed at; provider-assigned on a public zone's apex NS record. Private zones have no name servers and their keys are absent from this map."
  value       = { for key, zone in azurerm_dns_zone.zone : key => zone.name_servers }
}

output "virtual_network_link_ids" {
  description = "Map of \"<zone_key>.<link_key>\" => full ARM resource ID of each private-zone virtual network link."
  value       = { for key, link in azurerm_private_dns_zone_virtual_network_link.link : key => link.id }
}
