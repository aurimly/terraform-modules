output "load_balancer_ids" {
  description = "Map of load balancer key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/loadBalancers/<name>\")."
  value       = { for key, lb in azurerm_lb.lb : key => lb.id }
}

output "load_balancer_names" {
  description = "Map of load balancer key => load balancer name."
  value       = { for key, lb in azurerm_lb.lb : key => lb.name }
}

output "load_balancer_private_ip_addresses" {
  description = "Map of load balancer key => list of private IP addresses assigned across its frontend IP configurations, empty for public-only load balancers."
  value       = { for key, lb in azurerm_lb.lb : key => lb.private_ip_addresses }
}

output "frontend_ip_configuration_ids" {
  description = "Map of \"<lb_key>.<frontend_key>\" => full ARM resource ID of the frontend IP configuration (\"<lb_id>/frontendIPConfigurations/<name>\"). The provider exports frontends as an unnamed block list, so the module synthesizes the ID from the load balancer ID and the input names instead of re-keying a positional list."
  value = merge([for lb_key, lb in azurerm_lb.lb : {
    for fe_key, fe in var.load_balancers[lb_key].frontend_ip_configurations :
    "${lb_key}.${fe_key}" => "${lb.id}/frontendIPConfigurations/${fe.name}"
  }]...)
}

output "public_ip_ids" {
  description = "Map of public_ip key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>\"). Covers the in-module public_ips only — frontends referencing externally supplied IPs keep their outputs with the azure/public-ip module."
  value       = local.public_ip_ids
}

output "backend_address_pool_ids" {
  description = "Map of \"<lb_key>.<pool_key>\" => full ARM resource ID of the backend address pool (\"<lb_id>/backendAddressPools/<name>\")."
  value       = { for key, pool in azurerm_lb_backend_address_pool.pool : key => pool.id }
}

output "backend_address_pool_address_ids" {
  description = "Map of \"<lb_key>.<pool_key>.<address_key>\" => full ARM resource ID of the pool address (\"<pool_id>/addresses/<name>\")."
  value       = { for key, addr in azurerm_lb_backend_address_pool_address.address : key => addr.id }
}

output "nic_backend_address_pool_association_ids" {
  description = "Map of \"<lb_key>.<pool_key>.<assoc_key>\" => Terraform resource ID of the NIC-to-pool association — a Terraform-side composite, not an ARM ID (see Import)."
  value       = { for key, nic in azurerm_network_interface_backend_address_pool_association.nic : key => nic.id }
}

output "probe_ids" {
  description = "Map of \"<lb_key>.<probe_key>\" => full ARM resource ID of the probe (\"<lb_id>/probes/<name>\")."
  value       = { for key, probe in azurerm_lb_probe.probe : key => probe.id }
}

output "rule_ids" {
  description = "Map of \"<lb_key>.<rule_key>\" => full ARM resource ID of the load balancing rule (\"<lb_id>/loadBalancingRules/<name>\")."
  value       = { for key, rule in azurerm_lb_rule.rule : key => rule.id }
}

output "nat_rule_ids" {
  description = "Map of \"<lb_key>.<nat_rule_key>\" => full ARM resource ID of the inbound NAT rule (\"<lb_id>/inboundNatRules/<name>\")."
  value       = { for key, rule in azurerm_lb_nat_rule.nat_rule : key => rule.id }
}

output "nat_pool_ids" {
  description = "Map of \"<lb_key>.<nat_pool_key>\" => full ARM resource ID of the inbound NAT pool (\"<lb_id>/inboundNatPools/<name>\")."
  value       = { for key, pool in azurerm_lb_nat_pool.nat_pool : key => pool.id }
}

output "outbound_rule_ids" {
  description = "Map of \"<lb_key>.<outbound_rule_key>\" => full ARM resource ID of the outbound rule (\"<lb_id>/outboundRules/<name>\")."
  value       = { for key, rule in azurerm_lb_outbound_rule.outbound_rule : key => rule.id }
}
