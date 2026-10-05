output "route_ids" {
  description = "Map of route key => route ID."
  value       = { for key, route in cloudflare_workers_route.route : key => route.id }
}

output "route_patterns" {
  description = "Map of route key => route pattern."
  value       = { for key, route in cloudflare_workers_route.route : key => route.pattern }
}

output "route_scripts" {
  description = "Map of route key => attached Worker script name (null where unattached)."
  value       = { for key, route in cloudflare_workers_route.route : key => route.script }
}
