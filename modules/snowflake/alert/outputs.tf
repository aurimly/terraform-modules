output "alert_fully_qualified_names" {
  description = "Map of alert key => fully qualified name (database.schema.name) — use when the alert is referenced elsewhere in the provider, e.g. in GRANT statements or in an integration SQL action."
  value       = { for k, a in snowflake_alert.alert : k => a.fully_qualified_name }
}

output "alert_ids" {
  description = "Map of alert key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, a in snowflake_alert.alert : k => a.id }
}
