output "gateway_ids" {
  description = "Map of gateway key => Transit Gateway ID (tgw-...)."
  value       = { for k, g in aws_ec2_transit_gateway.gw : k => g.id }
}

output "gateway_arns" {
  description = "Map of gateway key => Transit Gateway ARN."
  value       = { for k, g in aws_ec2_transit_gateway.gw : k => g.arn }
}

output "gateway_owner_ids" {
  description = "Map of gateway key => account ID of the gateway owner (RAM sharing)."
  value       = { for k, g in aws_ec2_transit_gateway.gw : k => g.owner_id }
}

output "gateway_default_association_route_table_ids" {
  description = "Map of gateway key => ID of the default association route table (computed; the key to wiring routes into the default RT)."
  value       = { for k, g in aws_ec2_transit_gateway.gw : k => g.association_default_route_table_id }
}

output "gateway_default_propagation_route_table_ids" {
  description = "Map of gateway key => ID of the default propagation route table (computed)."
  value       = { for k, g in aws_ec2_transit_gateway.gw : k => g.propagation_default_route_table_id }
}

output "gateway_cidr_blocks" {
  description = "Map of gateway key => list of configured CIDR blocks."
  value       = { for k, g in aws_ec2_transit_gateway.gw : k => tolist(g.transit_gateway_cidr_blocks) }
}

output "route_table_ids" {
  description = "Map of route table key => route table ID (tgw-rt-...), keyed by the route_tables entry's own map key."
  value       = { for k, t in aws_ec2_transit_gateway_route_table.rt : k => t.id }
}

output "route_table_arns" {
  description = "Map of route table key => route table ARN."
  value       = { for k, t in aws_ec2_transit_gateway_route_table.rt : k => t.arn }
}

output "vpc_attachment_ids" {
  description = "Map of VPC attachment key => attachment ID (tgw-attach-...); feeds associations, propagations and routes here and any consumer-side route table tooling."
  value       = { for k, a in aws_ec2_transit_gateway_vpc_attachment.vpc : k => a.id }
}

output "vpc_attachment_arns" {
  description = "Map of VPC attachment key => attachment ARN."
  value       = { for k, a in aws_ec2_transit_gateway_vpc_attachment.vpc : k => a.arn }
}

output "peering_attachment_ids" {
  description = "Map of peering key => peering attachment ID (tgw-attach-...)."
  value       = { for k, p in aws_ec2_transit_gateway_peering_attachment.peering : k => p.id }
}

output "peering_attachment_states" {
  description = "Map of peering key => peering state (pending_acceptance, modifying, available, deleting, deleted, failed, pending_removal, rejected, rejecting, failing)."
  value       = { for k, p in aws_ec2_transit_gateway_peering_attachment.peering : k => p.state }
}

output "route_ids" {
  description = "Map of route key => route ID (route table ID and destination combined)."
  value       = { for k, r in aws_ec2_transit_gateway_route.route : k => r.id }
}

output "association_ids" {
  description = "Map of association key => association ID, keyed by the associations entry's own map key."
  value       = { for k, a in aws_ec2_transit_gateway_route_table_association.association : k => a.id }
}

output "propagation_ids" {
  description = "Map of propagation key => propagation ID, keyed by the propagations entry's own map key."
  value       = { for k, p in aws_ec2_transit_gateway_route_table_propagation.propagation : k => p.id }
}
