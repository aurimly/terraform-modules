output "variable_names" {
  description = "Map of variable key => variable name."
  value       = { for k, v in github_actions_variable.variable : k => v.variable_name }
}
