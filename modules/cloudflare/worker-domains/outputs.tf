output "domain_ids" {
  description = "Map of hostname => Workers custom domain ID."
  value       = { for k, d in cloudflare_workers_custom_domain.domain : k => d.id }
}

output "domain_hostnames" {
  description = "Map of hostname => hostname (the custom domain)."
  value       = { for k, d in cloudflare_workers_custom_domain.domain : k => d.hostname }
}

output "domain_services" {
  description = "Map of hostname => Worker service name."
  value       = { for k, d in cloudflare_workers_custom_domain.domain : k => d.service }
}
