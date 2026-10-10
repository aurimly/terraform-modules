output "key_import_ids" {
  description = "Map of deploy key key => resource ID (<repository>:<key_id>, usable directly for import)."
  value       = { for k, key in github_repository_deploy_key.key : k => key.id }
}

output "key_titles" {
  description = "Map of deploy key key => title actually set (each.map-key when title was not given)."
  value       = { for k, key in github_repository_deploy_key.key : k => coalesce(var.deploy_keys[k].title, k) }
}
