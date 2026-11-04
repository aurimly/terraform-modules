output "resource_monitor_fully_qualified_names" {
  description = "Map of resource monitor key => fully qualified name. Use for warehouse attachment (`resource_monitor` on snowflake_warehouse) and passes into notify_users references elsewhere in the provider."
  value       = { for k, m in snowflake_resource_monitor.monitor : k => m.fully_qualified_name }
}

output "resource_monitor_ids" {
  description = "Map of resource monitor key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, m in snowflake_resource_monitor.monitor : k => m.id }
}
