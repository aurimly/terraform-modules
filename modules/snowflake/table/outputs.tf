output "table_fully_qualified_names" {
  description = "Map of table key => fully qualified name (quoted \"database\".\"schema\".\"table\" form). Feed into snowflake/stream table, snowflake/pipe copy_statement and consumer-side references."
  value       = { for k, t in snowflake_table.table : k => t.fully_qualified_name }
}

output "table_ids" {
  description = "Map of table key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, t in snowflake_table.table : k => t.id }
}
