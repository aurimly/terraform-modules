output "grant_ids" {
  description = "Map of grant key => Terraform provider ID (constructed identifier, e.g. \"role\"|false|false|SELECT|OnSchemaObject|OnObject|TABLE|\"db\".\"schema\".\"table\" — used for imports; the resource exposes no fully_qualified_name read-only attribute)."
  value       = { for k, g in snowflake_grant_privileges_to_account_role.grant : k => g.id }
}
