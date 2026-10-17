output "label_names" {
  description = "Map of label key => display name set on GitHub (equals the map key)."
  value       = { for key, label in github_issue_label.label : key => label.name }
}

output "label_urls" {
  description = "Map of label key => label URL on GitHub."
  value       = { for key, label in github_issue_label.label : key => label.url }
}
