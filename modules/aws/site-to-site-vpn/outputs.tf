output "vpn_gateway_ids" {
  description = "Map of VGW key => Virtual Private Gateway ID (vgw-...)."
  value       = { for k, g in aws_vpn_gateway.vpn_gateway : k => g.id }
}

output "vpn_gateway_arns" {
  description = "Map of VGW key => Virtual Private Gateway ARN."
  value       = { for k, g in aws_vpn_gateway.vpn_gateway : k => g.arn }
}

output "customer_gateway_ids" {
  description = "Map of customer gateway key => Customer Gateway ID (cgw-...)."
  value       = { for k, g in aws_customer_gateway.gateway : k => g.id }
}

output "connection_ids" {
  description = "Map of connection key => VPN connection ID (vpn-...)."
  value       = { for k, c in aws_vpn_connection.connection : k => c.id }
}

output "connection_arns" {
  description = "Map of connection key => VPN connection ARN."
  value       = { for k, c in aws_vpn_connection.connection : k => c.arn }
}

output "tunnel1_addresses" {
  description = "Map of connection key => tunnel 1 outside IP address. Enter as a GCP external_gateways interface (id 0) pointing at this connection."
  value       = { for k, c in aws_vpn_connection.connection : k => c.tunnel1_address }
}

output "tunnel2_addresses" {
  description = "Map of connection key => tunnel 2 outside IP address. Register as the second GCP external_gateways interface (id 1)."
  value       = { for k, c in aws_vpn_connection.connection : k => c.tunnel2_address }
}

output "tunnel1_cgw_inside_addresses" {
  description = "Map of connection key => tunnel 1 link-local address on the customer (GCP) side; pair the BGP session's peer address with this."
  value       = { for k, c in aws_vpn_connection.connection : k => c.tunnel1_cgw_inside_address }
}

output "tunnel2_cgw_inside_addresses" {
  description = "Map of connection key => tunnel 2 link-local address on the customer (GCP) side."
  value       = { for k, c in aws_vpn_connection.connection : k => c.tunnel2_cgw_inside_address }
}

output "tunnel1_bgp_asns" {
  description = "Map of connection key => tunnel 1 BGP ASN on the AWS side (amazon_side_asn of the attached VGW/TGW)."
  value       = { for k, c in aws_vpn_connection.connection : k => c.tunnel1_bgp_asn }
}

output "tunnel2_bgp_asns" {
  description = "Map of connection key => tunnel 2 BGP ASN on the AWS side."
  value       = { for k, c in aws_vpn_connection.connection : k => c.tunnel2_bgp_asn }
}
