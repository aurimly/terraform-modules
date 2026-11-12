output "schema_fully_qualified_names" {
  description = "Map of schema key => fully qualified name (quoted \"database\".\"schema\" form). Feed into snowflake/grant-privileges schema-level targets and consumer-side references."
  value       = { for k, s in snowflake_schema.schema : k => s.fully_qualified_name }
}

output "schema_ids" {
  description = "Map of schema key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, s in snowflake_schema.schema : k => s.id }
}
