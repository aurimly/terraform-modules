output "stream_fully_qualified_names" {
  description = "Map of stream key => fully qualified name (quoted \"database\".\"schema\".\"stream\" form). Feed into task when-conditions (SYSTEM$STREAM_HAS_DATA) and consumer-side references."
  value       = { for k, s in snowflake_stream_on_table.stream : k => s.fully_qualified_name }
}

output "stream_ids" {
  description = "Map of stream key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, s in snowflake_stream_on_table.stream : k => s.id }
}
