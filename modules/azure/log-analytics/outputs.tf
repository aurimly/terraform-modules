output "workspace_ids" {
  description = "Map of workspace key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>\")."
  value       = { for key, workspace in azurerm_log_analytics_workspace.workspace : key => workspace.id }
}

output "workspace_names" {
  description = "Map of workspace key => workspace name."
  value       = { for key, workspace in azurerm_log_analytics_workspace.workspace : key => workspace.name }
}

output "workspace_customer_ids" {
  description = "Map of workspace key => workspace Customer ID (GUID) — the \"workspace_id\" every agent, DCR and API call carries."
  value       = { for key, workspace in azurerm_log_analytics_workspace.workspace : key => workspace.workspace_id }
}

output "workspace_primary_shared_keys" {
  description = "Map of workspace key => primary shared key (sensitive — see Notes)."
  value       = { for key, workspace in azurerm_log_analytics_workspace.workspace : key => workspace.primary_shared_key }
  sensitive   = true
}

output "workspace_secondary_shared_keys" {
  description = "Map of workspace key => secondary shared key (sensitive — see Notes)."
  value       = { for key, workspace in azurerm_log_analytics_workspace.workspace : key => workspace.secondary_shared_key }
  sensitive   = true
}

output "linked_service_names" {
  description = "Map of \"<workspace_key>.<link_key>\" => generated link name (\"<workspace-name>/<type>\" form — e.g. \"log-ops/Automation\")."
  value       = { for key, link in azurerm_log_analytics_linked_service.linked_service : key => link.name }
}

output "linked_service_ids" {
  description = "Map of \"<workspace_key>.<link_key>\" => full ARM resource ID of the linked-service link."
  value       = { for key, link in azurerm_log_analytics_linked_service.linked_service : key => link.id }
}

output "linked_storage_account_ids" {
  description = "Map of \"<workspace_key>.<link_key>\" => full ARM resource ID of the linked-storage link."
  value       = { for key, link in azurerm_log_analytics_linked_storage_account.linked_storage : key => link.id }
}
