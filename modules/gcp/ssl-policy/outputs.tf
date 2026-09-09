output "policy_ids" {
  description = "Map of SSL policy key => policy id."
  value       = { for k, s in google_compute_ssl_policy.policy : k => s.id }
}

output "policy_self_links" {
  description = "Map of SSL policy key => self link (feeds ssl_policy on target HTTPS proxies in gcp/load-balancer)."
  value       = { for k, s in google_compute_ssl_policy.policy : k => s.self_link }
}

output "policy_profiles" {
  description = "Map of SSL policy key => profile."
  value       = { for k, s in google_compute_ssl_policy.policy : k => s.profile }
}

output "policy_enabled_features" {
  description = "Map of SSL policy key => the features enabled by the policy (computed from profile or custom_features)."
  value       = { for k, s in google_compute_ssl_policy.policy : k => s.enabled_features }
}
