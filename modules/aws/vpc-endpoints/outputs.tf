output "endpoint_ids" {
  description = "Map of endpoint key => VPC endpoint ID (vpce-...)."
  value       = { for k, e in aws_vpc_endpoint.this : k => e.id }
}

output "endpoint_arns" {
  description = "Map of endpoint key => VPC endpoint ARN."
  value       = { for k, e in aws_vpc_endpoint.this : k => e.arn }
}

output "prefix_list_ids" {
  description = "Map of endpoint key => prefix list ID of the exposed service (for security-group egress rules), null for interface endpoints. Covers all endpoint keys."
  value       = { for k, e in var.vpc_endpoints : k => e.vpc_endpoint_type == "Gateway" ? aws_vpc_endpoint.this[k].prefix_list_id : null }
}

output "cidr_blocks" {
  description = "Map of endpoint key => CIDR blocks of the exposed service, null for interface endpoints. Covers all endpoint keys."
  value       = { for k, e in var.vpc_endpoints : k => e.vpc_endpoint_type == "Gateway" ? aws_vpc_endpoint.this[k].cidr_blocks : null }
}

output "dns_names" {
  description = "Map of endpoint key => DNS names of the endpoint, null for gateway endpoints. Covers all endpoint keys."
  value       = { for k, e in var.vpc_endpoints : k => e.vpc_endpoint_type == "Interface" ? distinct([for de in aws_vpc_endpoint.this[k].dns_entry : de.dns_name]) : null }
}

output "hosted_zone_ids" {
  description = "Map of endpoint key => private hosted zone IDs of the endpoint's DNS entries, null for gateway endpoints. Covers all endpoint keys."
  value       = { for k, e in var.vpc_endpoints : k => e.vpc_endpoint_type == "Interface" ? distinct([for de in aws_vpc_endpoint.this[k].dns_entry : de.hosted_zone_id]) : null }
}

output "network_interface_ids" {
  description = "Map of endpoint key => ENI IDs of the endpoint (for NACL and flow-log wiring), null for gateway endpoints. Covers all endpoint keys."
  value       = { for k, e in var.vpc_endpoints : k => e.vpc_endpoint_type == "Interface" ? aws_vpc_endpoint.this[k].network_interface_ids : null }
}

output "states" {
  description = "Map of endpoint key => endpoint state (available, pendingAcceptance, ...)."
  value       = { for k, e in aws_vpc_endpoint.this : k => e.state }
}
