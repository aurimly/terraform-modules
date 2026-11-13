output "task_fully_qualified_names" {
  description = "Map of task key => fully qualified name (quoted \"database\".\"schema\".\"task\" form). Feed into snowflake/grant-privileges, and pass back into the same module's after/finalize to wire task DAGs."
  value       = { for k, t in snowflake_task.task : k => t.fully_qualified_name }
}

output "task_ids" {
  description = "Map of task key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, t in snowflake_task.task : k => t.id }
}
