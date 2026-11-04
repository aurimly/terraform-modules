output "user_fully_qualified_names" {
  description = "Map of user key => fully qualified name. Feed into snowflake/role-grant (user_name) and consumer-side GRANT statements."
  value       = { for k, u in snowflake_user.user : k => u.fully_qualified_name }
}

output "user_ids" {
  description = "Map of user key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, u in snowflake_user.user : k => u.id }
}
