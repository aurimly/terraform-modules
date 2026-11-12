output "database_fully_qualified_names" {
  description = "Map of database key => fully qualified name. Use in grants (object_name must be the quoted fully qualified name) and consumer-side references."
  value       = { for k, d in snowflake_database.database : k => d.fully_qualified_name }
}

output "database_ids" {
  description = "Map of database key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, d in snowflake_database.database : k => d.id }
}
