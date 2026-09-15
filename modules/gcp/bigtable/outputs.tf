output "instance_names" {
  description = "Map of instance key => instance name."
  value       = { for k, i in google_bigtable_instance.instance : k => i.name }
}

output "instance_ids" {
  description = "Map of instance key => instance id (projects/<project>/instances/<name>)."
  value       = { for k, i in google_bigtable_instance.instance : k => i.id }
}

output "table_ids" {
  description = "Map of '<instance key>/<table key>' => table id (projects/<project>/instances/<instance>/tables/<name>)."
  value       = { for k, t in google_bigtable_table.table : k => t.id }
}

output "app_profile_ids" {
  description = "Map of '<instance key>/<profile key>' => app profile id (projects/<project>/instances/<instance>/appProfiles/<app_profile_id>)."
  value       = { for k, p in google_bigtable_app_profile.profile : k => p.id }
}

output "gc_policy_keys" {
  description = "Map of '<instance key>/<table key>/<column family>' => the same composite key. google_bigtable_gc_policy does not export a usable id (and does not support import); the key itself identifies the policy."
  value       = { for k in keys(google_bigtable_gc_policy.policy) : k => k }
}

output "instance_iam_binding_roles" {
  description = "Map of '<instance key>/<binding key>' => role."
  value       = { for k, b in google_bigtable_instance_iam_binding.binding : k => b.role }
}

output "table_iam_binding_roles" {
  description = "Map of '<instance key>/<table key>/<binding key>' => role."
  value       = { for k, b in google_bigtable_table_iam_binding.binding : k => b.role }
}
