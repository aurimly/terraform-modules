output "pipe_fully_qualified_names" {
  description = "Map of pipe key => fully qualified name (quoted \"database\".\"schema\".\"pipe\" form). Feed into consumer-side references and grant workflows."
  value       = { for k, p in snowflake_pipe.pipe : k => p.fully_qualified_name }
}

output "pipe_ids" {
  description = "Map of pipe key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, p in snowflake_pipe.pipe : k => p.id }
}
