output "action_group_ids" {
  description = "Map of action-group key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Insights/actionGroups/<name>\") — feeds every alert's action wiring in this module's other variables."
  value       = { for key, group in azurerm_monitor_action_group.action_group : key => group.id }
}

output "metric_alert_ids" {
  description = "Map of metric-alert key => full ARM resource ID."
  value       = { for key, alert in azurerm_monitor_metric_alert.metric_alert : key => alert.id }
}

output "activity_log_alert_ids" {
  description = "Map of activity-log-alert key => full ARM resource ID."
  value       = { for key, alert in azurerm_monitor_activity_log_alert.activity_log_alert : key => alert.id }
}

output "scheduled_query_rule_ids" {
  description = "Map of scheduled-query-rule key => full ARM resource ID."
  value       = { for key, rule in azurerm_monitor_scheduled_query_rules_alert_v2.scheduled_query_rule : key => rule.id }
}

output "diagnostic_setting_ids" {
  description = "Map of diagnostic-setting key => full ARM resource ID (\"<target_resource_id>/providers/microsoft.insights/diagnosticSettings/<name>\")."
  value       = { for key, setting in azurerm_monitor_diagnostic_setting.diagnostic_setting : key => setting.id }
}
