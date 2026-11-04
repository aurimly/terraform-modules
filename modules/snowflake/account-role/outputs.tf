output "account_role_fully_qualified_names" {
  description = "Map of account role key => fully qualified name. Feed directly into the account_role_name input of snowflake/grant-privileges and role_name of snowflake/role-grant."
  value       = { for k, r in snowflake_account_role.role : k => r.fully_qualified_name }
}

output "account_role_ids" {
  description = "Map of account role key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, r in snowflake_account_role.role : k => r.id }
}
