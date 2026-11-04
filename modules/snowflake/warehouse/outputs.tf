output "warehouse_fully_qualified_names" {
  description = "Map of warehouse key => fully qualified name. Use in user default_warehouse, grants (object_name must be the quoted fully qualified name) and resource-monitor attachment references."
  value       = { for k, w in snowflake_warehouse.warehouse : k => w.fully_qualified_name }
}

output "warehouse_ids" {
  description = "Map of warehouse key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, w in snowflake_warehouse.warehouse : k => w.id }
}
