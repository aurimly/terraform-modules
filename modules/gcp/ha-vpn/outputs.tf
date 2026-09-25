output "router_names" {
  description = "Map of router key => created Cloud Router name."
  value       = { for k, r in google_compute_router.router : k => r.name }
}

output "router_self_links" {
  description = "Map of router key => created Cloud Router self link."
  value       = { for k, r in google_compute_router.router : k => r.self_link }
}

output "gateway_names" {
  description = "Map of gateway key => HA VPN gateway name."
  value       = { for k, g in google_compute_ha_vpn_gateway.gateway : k => g.name }
}

output "gateway_self_links" {
  description = "Map of gateway key => HA VPN gateway self link."
  value       = { for k, g in google_compute_ha_vpn_gateway.gateway : k => g.self_link }
}

output "vpn_gateway_addresses" {
  description = "Map of gateway key => list of the gateway's two public interface addresses (index 0 and 1). These are the addresses to register as AWS-side reachable peer endpoints."
  value       = { for k, g in google_compute_ha_vpn_gateway.gateway : k => [for i in g.vpn_interfaces : i.ip_address] }
}

output "external_gateway_names" {
  description = "Map of external gateway key => external VPN gateway name."
  value       = { for k, g in google_compute_external_vpn_gateway.external_gateway : k => g.name }
}

output "external_gateway_self_links" {
  description = "Map of external gateway key => external VPN gateway self link."
  value       = { for k, g in google_compute_external_vpn_gateway.external_gateway : k => g.self_link }
}

output "tunnel_names" {
  description = "Map of tunnel key => VPN tunnel name."
  value       = { for k, t in google_compute_vpn_tunnel.tunnel : k => t.name }
}

output "tunnel_self_links" {
  description = "Map of tunnel key => VPN tunnel self link."
  value       = { for k, t in google_compute_vpn_tunnel.tunnel : k => t.self_link }
}

output "tunnel_statuses" {
  description = "Map of tunnel key => tunnel status as reported by the API (e.g. awaiting-connection-config, tunnel-established); converges to tunnel-established once the AWS side's matching tunnel is up with the same PSK."
  value       = { for k, t in google_compute_vpn_tunnel.tunnel : k => t.detailed_status }
}
