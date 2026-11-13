output "view_fully_qualified_names" {
  description = "Map of view key => fully qualified name (quoted \"database\".\"schema\".\"view\" form). Feed into snowflake/grant-privileges and consumer-side references."
  value       = { for k, v in snowflake_view.view : k => v.fully_qualified_name }
}

output "view_ids" {
  description = "Map of view key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, v in snowflake_view.view : k => v.id }
}
