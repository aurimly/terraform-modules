output "nat_gateway_ids" {
  description = "Map of NAT key => NAT gateway ID (nat-...)."
  value       = { for k, n in aws_nat_gateway.nat : k => n.id }
}

output "nat_gateway_network_interface_ids" {
  description = "Map of NAT key => ENI ID backing the NAT gateway (for NACL and flow-log wiring)."
  value       = { for k, n in aws_nat_gateway.nat : k => n.network_interface_id }
}

output "allocation_ids" {
  description = "Map of NAT key => resolved EIP allocation ID (created by the module or passed in), null for private NAT gateways. Covers all NAT keys."
  value       = { for k, n in var.nat_gateways : k => n.connectivity_type != "public" ? null : coalesce(n.allocation_id, try(aws_eip.nat[k].allocation_id, null)) }
}

output "public_ips" {
  description = "Map of NAT key => public IPv4 address, null for private NAT gateways. Covers all NAT keys."
  value       = { for k, n in var.nat_gateways : k => n.connectivity_type != "public" ? null : coalesce(try(aws_eip.nat[k].public_ip, null), try(aws_nat_gateway.nat[k].public_ip, null)) }
}
