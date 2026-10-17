output "variable_names" {
  description = "Map of variable key => variable name."
  value       = { for key, v in github_actions_organization_variable.variable : key => v.variable_name }
}

output "variable_values" {
  description = "Map of variable key => current value — variables (unlike secrets) are readable back, so this output reflects live state."
  value       = { for key, v in github_actions_organization_variable.variable : key => v.value }
}
