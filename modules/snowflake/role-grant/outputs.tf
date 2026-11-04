output "role_grant_ids" {
  description = "Map of role grant key => Terraform provider ID (constructed identifier, e.g. \"role\"|USER|\"user\"; used for imports — the resource exposes no fully_qualified_name read-only attribute)."
  value       = { for k, g in snowflake_grant_account_role.grant : k => g.id }
}
