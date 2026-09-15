output "tcp_proxy_names" {
  description = "Map of TCP proxy key => proxy name."
  value       = { for k, p in google_compute_target_tcp_proxy.tcp_proxy : k => p.name }
}

output "tcp_proxy_self_links" {
  description = "Map of TCP proxy key => proxy self link (wire into gcp/load-balancer forwarding_rules[].target or forwarding_rules.target)."
  value       = { for k, p in google_compute_target_tcp_proxy.tcp_proxy : k => p.self_link }
}

output "regional_tcp_proxy_names" {
  description = "Map of regional TCP proxy key => proxy name."
  value       = { for k, p in google_compute_region_target_tcp_proxy.regional_tcp_proxy : k => p.name }
}

output "regional_tcp_proxy_self_links" {
  description = "Map of regional TCP proxy key => proxy self link (wire into regional forwarding rules[].target)."
  value       = { for k, p in google_compute_region_target_tcp_proxy.regional_tcp_proxy : k => p.self_link }
}

output "ssl_proxy_names" {
  description = "Map of SSL proxy key => proxy name."
  value       = { for k, p in google_compute_target_ssl_proxy.ssl_proxy : k => p.name }
}

output "ssl_proxy_self_links" {
  description = "Map of SSL proxy key => proxy self link (wire into gcp/load-balancer global_forwarding_rules[].target)."
  value       = { for k, p in google_compute_target_ssl_proxy.ssl_proxy : k => p.self_link }
}

output "grpc_proxy_names" {
  description = "Map of gRPC proxy key => proxy name."
  value       = { for k, p in google_compute_target_grpc_proxy.grpc_proxy : k => p.name }
}

output "grpc_proxy_self_links" {
  description = "Map of gRPC proxy key => proxy self link (wire into gcp/load-balancer global_forwarding_rules[].target)."
  value       = { for k, p in google_compute_target_grpc_proxy.grpc_proxy : k => p.self_link }
}
