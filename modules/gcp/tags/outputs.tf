output "tag_key_ids" {
  description = "Map of key => provider id (tagKeys/{numeric id}) — the identifier bindings and downstream resources consume."
  value       = { for k, key in google_tags_tag_key.key : k => key.id }
}

output "tag_key_names" {
  description = "Map of key => generated numeric id (the `name` attribute, without the tagKeys/ prefix)."
  value       = { for k, key in google_tags_tag_key.key : k => key.name }
}

output "tag_key_namespaced_names" {
  description = "Map of key => namespaced name ({parent namespace}/{short_name}, e.g. example-org/example-env) — the form policy engines display."
  value       = { for k, key in google_tags_tag_key.key : k => key.namespaced_name }
}

output "tag_value_ids" {
  description = "Map of value key => provider id (tagValues/{numeric id}) — what google_tags_tag_binding and tag policy inputs consume."
  value       = { for k, value in google_tags_tag_value.value : k => value.id }
}

output "tag_value_names" {
  description = "Map of value key => generated numeric id (the `name` attribute, without the tagValues/ prefix)."
  value       = { for k, value in google_tags_tag_value.value : k => value.name }
}

output "tag_value_namespaced_names" {
  description = "Map of value key => namespaced name ({parent namespace}/{tag key short_name}/{short_name})."
  value       = { for k, value in google_tags_tag_value.value : k => value.namespaced_name }
}
