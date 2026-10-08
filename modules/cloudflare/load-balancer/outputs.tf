output "monitor_ids" {
  description = "Health monitor IDs, keyed by monitor key."
  value       = { for k, m in cloudflare_load_balancer_monitor.monitor : k => m.id }
}

output "pool_ids" {
  description = "Origin pool IDs, keyed by pool key. Chains into other Terraform (e.g. a second module instance or raw resources) that must reference pools by ID."
  value       = { for k, p in cloudflare_load_balancer_pool.pool : k => p.id }
}

output "load_balancer_ids" {
  description = "Load balancer IDs, keyed by load balancer key."
  value       = { for k, lb in cloudflare_load_balancer.lb : k => lb.id }
}
