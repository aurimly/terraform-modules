output "integration_fully_qualified_names" {
  description = "Map of integration key => fully qualified name — integrate with alert actions (e.g. a SQL action calling `CALL SYSTEM$SEND_EMAIL(...)` with this integration) and mention in GRANT statements."
  value       = { for k, i in snowflake_email_notification_integration.integration : k => i.fully_qualified_name }
}

output "integration_ids" {
  description = "Map of integration key => Terraform provider ID (constructed identifier for data sources, grants and imports)."
  value       = { for k, i in snowflake_email_notification_integration.integration : k => i.id }
}
