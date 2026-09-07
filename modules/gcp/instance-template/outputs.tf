output "template_names" {
  description = "Map of template key => instance template name (auto-generated when name_prefix is used)."
  value       = { for k, t in google_compute_instance_template.template : k => t.name }
}

output "template_ids" {
  description = "Map of template key => instance template ID (projects/{project}/global/instanceTemplates/{name})."
  value       = { for k, t in google_compute_instance_template.template : k => t.id }
}

output "template_self_links" {
  description = "Map of template key => instance template self link."
  value       = { for k, t in google_compute_instance_template.template : k => t.self_link }
}

output "template_self_link_uniques" {
  description = "Map of template key => instance template self_link_unique. Prefer this when passing into gcp/instance-group-manager versions.instance_template."
  value       = { for k, t in google_compute_instance_template.template : k => t.self_link_unique }
}
