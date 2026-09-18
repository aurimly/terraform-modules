output "instance_names" {
  description = "Map of instance key => instance name."
  value       = { for k, i in google_spanner_instance.instance : k => i.name }
}

output "instance_ids" {
  description = "Map of instance key => instance id (<project>/<name>)."
  value       = { for k, i in google_spanner_instance.instance : k => i.id }
}

output "database_ids" {
  description = "Map of '<instance key>/<database key>' => database id (<instance>/<name>)."
  value       = { for k, d in google_spanner_database.database : k => d.id }
}

output "instance_iam_binding_roles" {
  description = "Map of '<instance key>/<binding key>' => role."
  value       = { for k, b in google_spanner_instance_iam_binding.binding : k => b.role }
}

output "database_iam_binding_roles" {
  description = "Map of '<instance key>/<database key>/<binding key>' => role."
  value       = { for k, b in google_spanner_database_iam_binding.binding : k => b.role }
}
