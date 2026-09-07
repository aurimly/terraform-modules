output "health_check_names" {
  description = "Map of health check key => name."
  value       = { for k, c in google_compute_health_check.health_check : k => c.name }
}

output "health_check_self_links" {
  description = "Map of health check key => self link."
  value       = { for k, c in google_compute_health_check.health_check : k => c.self_link }
}

output "regional_health_check_names" {
  description = "Map of regional health check key => name."
  value       = { for k, c in google_compute_region_health_check.region_health_check : k => c.name }
}

output "regional_health_check_self_links" {
  description = "Map of regional health check key => self link."
  value       = { for k, c in google_compute_region_health_check.region_health_check : k => c.self_link }
}

output "backend_service_names" {
  description = "Map of backend service key => name."
  value       = { for k, s in google_compute_backend_service.backend_service : k => s.name }
}

output "backend_service_self_links" {
  description = "Map of backend service key => self link."
  value       = { for k, s in google_compute_backend_service.backend_service : k => s.self_link }
}

output "regional_backend_service_names" {
  description = "Map of regional backend service key => name."
  value       = { for k, s in google_compute_region_backend_service.region_backend_service : k => s.name }
}

output "regional_backend_service_self_links" {
  description = "Map of regional backend service key => self link."
  value       = { for k, s in google_compute_region_backend_service.region_backend_service : k => s.self_link }
}

output "backend_bucket_names" {
  description = "Map of backend bucket key => name."
  value       = { for k, b in google_compute_backend_bucket.backend_bucket : k => b.name }
}

output "backend_bucket_self_links" {
  description = "Map of backend bucket key => self link."
  value       = { for k, b in google_compute_backend_bucket.backend_bucket : k => b.self_link }
}

output "url_map_names" {
  description = "Map of URL map key => name."
  value       = { for k, m in google_compute_url_map.url_map : k => m.name }
}

output "url_map_self_links" {
  description = "Map of URL map key => self link."
  value       = { for k, m in google_compute_url_map.url_map : k => m.self_link }
}

output "url_map_ids" {
  description = "Map of URL map key => ID (projects/{project}/global/urlMaps/{name})."
  value       = { for k, m in google_compute_url_map.url_map : k => m.id }
}

output "regional_url_map_names" {
  description = "Map of regional URL map key => name."
  value       = { for k, m in google_compute_region_url_map.region_url_map : k => m.name }
}

output "regional_url_map_self_links" {
  description = "Map of regional URL map key => self link."
  value       = { for k, m in google_compute_region_url_map.region_url_map : k => m.self_link }
}

output "regional_url_map_ids" {
  description = "Map of regional URL map key => ID (projects/{project}/regions/{region}/urlMaps/{name})."
  value       = { for k, m in google_compute_region_url_map.region_url_map : k => m.id }
}

output "http_proxy_names" {
  description = "Map of target HTTP proxy key => name."
  value       = { for k, p in google_compute_target_http_proxy.http_proxy : k => p.name }
}

output "http_proxy_self_links" {
  description = "Map of target HTTP proxy key => self link."
  value       = { for k, p in google_compute_target_http_proxy.http_proxy : k => p.self_link }
}

output "https_proxy_names" {
  description = "Map of target HTTPS proxy key => name."
  value       = { for k, p in google_compute_target_https_proxy.https_proxy : k => p.name }
}

output "https_proxy_self_links" {
  description = "Map of target HTTPS proxy key => self link."
  value       = { for k, p in google_compute_target_https_proxy.https_proxy : k => p.self_link }
}

output "regional_http_proxy_names" {
  description = "Map of regional target HTTP proxy key => name."
  value       = { for k, p in google_compute_region_target_http_proxy.region_http_proxy : k => p.name }
}

output "regional_http_proxy_self_links" {
  description = "Map of regional target HTTP proxy key => self link."
  value       = { for k, p in google_compute_region_target_http_proxy.region_http_proxy : k => p.self_link }
}

output "regional_https_proxy_names" {
  description = "Map of regional target HTTPS proxy key => name."
  value       = { for k, p in google_compute_region_target_https_proxy.region_https_proxy : k => p.name }
}

output "regional_https_proxy_self_links" {
  description = "Map of regional target HTTPS proxy key => self link."
  value       = { for k, p in google_compute_region_target_https_proxy.region_https_proxy : k => p.self_link }
}

output "global_forwarding_rule_names" {
  description = "Map of global forwarding rule key => name."
  value       = { for k, r in google_compute_global_forwarding_rule.global_forwarding_rule : k => r.name }
}

output "global_forwarding_rule_self_links" {
  description = "Map of global forwarding rule key => self link."
  value       = { for k, r in google_compute_global_forwarding_rule.global_forwarding_rule : k => r.self_link }
}

output "global_forwarding_rule_ids" {
  description = "Map of global forwarding rule key => ID (projects/{project}/global/forwardingRules/{name})."
  value       = { for k, r in google_compute_global_forwarding_rule.global_forwarding_rule : k => r.id }
}

output "forwarding_rule_names" {
  description = "Map of regional forwarding rule key => name."
  value       = { for k, r in google_compute_forwarding_rule.forwarding_rule : k => r.name }
}

output "forwarding_rule_self_links" {
  description = "Map of regional forwarding rule key => self link."
  value       = { for k, r in google_compute_forwarding_rule.forwarding_rule : k => r.self_link }
}

output "forwarding_rule_ids" {
  description = "Map of regional forwarding rule key => ID (projects/{project}/regions/{region}/forwardingRules/{name})."
  value       = { for k, r in google_compute_forwarding_rule.forwarding_rule : k => r.id }
}
