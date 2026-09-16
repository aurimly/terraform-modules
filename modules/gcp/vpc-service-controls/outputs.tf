output "access_policy_names" {
  description = "Map of access policy key => numeric policy ID (the value Terraform composes child accessLevel/servicePerimeter resource names from)."
  value       = { for k, p in google_access_context_manager_access_policy.access_policy : k => p.name }
}

output "access_policy_titles" {
  description = "Map of access policy key => policy title."
  value       = { for k, p in google_access_context_manager_access_policy.access_policy : k => p.title }
}

output "access_level_names" {
  description = "Map of access level key => full access level resource name (accessPolicies/{policy_id}/accessLevels/{short_name}) for wiring into perimeter access_levels lists."
  value       = { for k, l in google_access_context_manager_access_level.access_level : k => l.name }
}

output "service_perimeter_names" {
  description = "Map of perimeter key => full perimeter resource name (accessPolicies/{policy_id}/servicePerimeters/{short_name})."
  value       = { for k, p in google_access_context_manager_service_perimeter.perimeter : k => p.name }
}

output "service_perimeter_etags" {
  description = "Map of perimeter key => perimeter etag."
  value       = { for k, p in google_access_context_manager_service_perimeter.perimeter : k => p.etag }
}
