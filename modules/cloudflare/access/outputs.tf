output "identity_provider_ids" {
  description = "Identity provider IDs, keyed by key."
  value       = { for k, idp in cloudflare_zero_trust_access_identity_provider.idp : k => idp.id }
}

output "policy_ids" {
  description = "Policy IDs, keyed by key. Chains into raw applications (inline policies are out of scope here) or into other stacks that attach policies by ID."
  value       = { for k, p in cloudflare_zero_trust_access_policy.policy : k => p.id }
}

output "application_ids" {
  description = "Application IDs, keyed by application key."
  value       = { for k, app in cloudflare_zero_trust_access_application.app : k => app.id }
}

output "application_auds" {
  description = "Application AUD values, keyed by application key — needed for service-token auth and API access checks."
  value       = { for k, app in cloudflare_zero_trust_access_application.app : k => app.aud }
}
