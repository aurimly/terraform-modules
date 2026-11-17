output "configuration_ids" {
  description = "Map of key => numeric configuration ID (config_id). This is the import ID base of akamai_appsec_configuration."
  value       = { for k, c in akamai_appsec_configuration.configuration : k => c.config_id }
}

output "configuration_latest_versions" {
  description = "Map of key => latest version of the configuration, read by the in-module name data source only after every mutation resource has applied (explicit depends_on)."
  value       = { for k, d in data.akamai_appsec_configuration.by_name : k => d.latest_version }
}

output "security_policy_ids" {
  description = "Nested map: configuration key => policy key => security policy ID (xxxx_123456)."
  value = {
    for ck in keys(var.configurations) : ck => {
      for pk, p in var.security_policies : pk => akamai_appsec_security_policy.policy[pk].security_policy_id
      if p.config_key == ck
    }
  }
}

output "rate_policy_ids" {
  description = "Map of key => numeric rate policy ID."
  value       = { for k, r in akamai_appsec_rate_policy.rate_policy : k => r.rate_policy_id }
}

output "match_target_ids" {
  description = "Map of key => numeric match target ID."
  value       = { for k, m in akamai_appsec_match_target.match_target : k => m.match_target_id }
}

output "activation_statuses" {
  description = "Map of key => activation status. Indicative only: see the README note on status not being proof of deployment."
  value       = { for k, a in akamai_appsec_activations.activation : k => a.status }
}
