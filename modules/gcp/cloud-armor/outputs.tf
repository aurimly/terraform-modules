output "policy_ids" {
  description = "Map of security policy key => policy id."
  value       = { for k, p in google_compute_security_policy.policy : k => p.id }
}

output "policy_self_links" {
  description = "Map of security policy key => self link (feeds security_policy on backend services and edge_security_policy on backend buckets in gcp/load-balancer)."
  value       = { for k, p in google_compute_security_policy.policy : k => p.self_link }
}

output "policy_fingerprints" {
  description = "Map of security policy key => fingerprint."
  value       = { for k, p in google_compute_security_policy.policy : k => p.fingerprint }
}
