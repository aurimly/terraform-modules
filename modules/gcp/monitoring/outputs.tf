output "dashboard_ids" {
  description = "Map of dashboard key => dashboard id."
  value       = { for k, d in google_monitoring_dashboard.dashboard : k => d.id }
}

output "alert_policy_names" {
  description = "Map of alert policy key => full alert policy resource name (projects/x/alertPolicies/123; usable as a channel reference elsewhere)."
  value       = { for k, p in google_monitoring_alert_policy.alert_policy : k => p.name }
}
