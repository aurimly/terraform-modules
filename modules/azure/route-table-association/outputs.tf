output "association_ids" {
  description = "Map of key => association resource ID (the subnet's full ARM resource ID, per the provider's id attribute)."
  value       = { for k, a in azurerm_subnet_route_table_association.association : k => a.id }
}
