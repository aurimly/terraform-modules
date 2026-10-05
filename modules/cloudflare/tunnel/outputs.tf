output "tunnel_ids" {
  description = "Map of tunnel key => tunnel ID (UUID)."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnel : key => tunnel.id }
}

output "tunnel_names" {
  description = "Map of tunnel key => tunnel name as managed in Cloudflare."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnel : key => tunnel.name }
}

output "tunnel_statuses" {
  description = "Map of tunnel key => tunnel status."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnel : key => tunnel.status }
}

output "tunnel_config_srcs" {
  description = "Map of tunnel key => config source (local or cloudflare)."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnel : key => tunnel.config_src }
}

output "tunnel_tokens" {
  description = "Map of tunnel key => connector token (only read when expose_tokens = true; the endpoint requires Write-scoped API permissions). Values land in state and are visible to anyone with state access."
  value       = { for key, token in data.cloudflare_zero_trust_tunnel_cloudflared_token.token : key => token.token }
  sensitive   = true
}

output "tunnel_secrets" {
  description = "Map of tunnel key => tunnel secret as provided in the input. Values land in state and are visible to anyone with state access; rotating the secret invalidates running connector credentials until restart."
  value       = { for key, tunnel in var.tunnels : key => tunnel.tunnel_secret }
  sensitive   = true
}

output "route_ids" {
  description = "Map of composite route key => route ID. Keys are \"<tunnel_key>/<route_key>\"."
  value       = { for key, route in cloudflare_zero_trust_tunnel_cloudflared_route.route : key => route.id }
}

output "route_networks" {
  description = "Map of composite route key => routed network CIDR. Keys are \"<tunnel_key>/<route_key>\"."
  value       = { for key, route in cloudflare_zero_trust_tunnel_cloudflared_route.route : key => route.network }
}

output "config_versions" {
  description = "Map of tunnel key => remotely-managed ingress config version."
  value       = { for key, config in cloudflare_zero_trust_tunnel_cloudflared_config.config : key => config.version }
}
