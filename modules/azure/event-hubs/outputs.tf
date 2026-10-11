output "namespace_ids" {
  description = "Map of namespace key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.EventHub/namespaces/<name>\")."
  value       = { for key, ns in azurerm_eventhub_namespace.namespace : key => ns.id }
}

output "namespace_names" {
  description = "Map of namespace key => namespace name."
  value       = { for key, ns in azurerm_eventhub_namespace.namespace : key => ns.name }
}

output "namespace_skus" {
  description = "Map of namespace key => SKU (Basic, Standard or Premium)."
  value       = { for key, ns in azurerm_eventhub_namespace.namespace : key => ns.sku }
}

output "eventhub_ids" {
  description = "Map of \"<namespace_key>.<hub_key>\" => full ARM resource ID of the event hub (\"<namespace_id>/eventhubs/<name>\")."
  value       = { for key, hub in azurerm_eventhub.hub : key => hub.id }
}

output "eventhub_partition_counts" {
  description = "Map of \"<namespace_key>.<hub_key>\" => partition count — consumers size their maximum reader parallelism to it."
  value       = { for key, hub in azurerm_eventhub.hub : key => hub.partition_count }
}

output "consumer_group_ids" {
  description = "Map of \"<namespace_key>.<hub_key>.<consumer_group_key>\" => full ARM resource ID of the consumer group (\"<hub_id>/consumerGroups/<name>\")."
  value       = { for key, cg in azurerm_eventhub_consumer_group.consumer_group : key => cg.id }
}

output "namespace_authorization_rule_ids" {
  description = "Map of \"<namespace_key>.<rule_key>\" => full ARM resource ID of the namespace-scoped authorization rule (\"<namespace_id>/authorizationRules/<name>\")."
  value       = { for key, rule in azurerm_eventhub_namespace_authorization_rule.namespace_rule : key => rule.id }
}

output "eventhub_authorization_rule_ids" {
  description = "Map of \"<namespace_key>.<hub_key>.<rule_key>\" => full ARM resource ID of the event-hub-scoped authorization rule (\"<hub_id>/authorizationRules/<name>\")."
  value       = { for key, rule in azurerm_eventhub_authorization_rule.hub_rule : key => rule.id }
}

output "namespace_authorization_rule_keys" {
  description = "Map of \"<namespace_key>.<rule_key>\" => { primary_key = ..., secondary_key = ..., primary_connection_string = ..., secondary_connection_string = ... } for the namespace-scoped SAS rules. Sensitive: every member is a provider-sensitive credential — keys and connection strings land in state and are visible to anyone with state access; pull them from state or the pipeline, not from logs, and rotate in the portal or CLI (regeneration is not managed by this module)."
  value = {
    for key, rule in azurerm_eventhub_namespace_authorization_rule.namespace_rule : key => {
      primary_key                 = rule.primary_key
      secondary_key               = rule.secondary_key
      primary_connection_string   = rule.primary_connection_string
      secondary_connection_string = rule.secondary_connection_string
    }
  }
  sensitive = true
}

output "eventhub_authorization_rule_keys" {
  description = "Map of \"<namespace_key>.<hub_key>.<rule_key>\" => { primary_key = ..., secondary_key = ..., primary_connection_string = ..., secondary_connection_string = ... } for the event-hub-scoped SAS rules. Sensitive: every member is a provider-sensitive credential — keys and connection strings land in state and are visible to anyone with state access; pull them from state or the pipeline, not from logs, and rotate in the portal or CLI (regeneration is not managed by this module)."
  value = {
    for key, rule in azurerm_eventhub_authorization_rule.hub_rule : key => {
      primary_key                 = rule.primary_key
      secondary_key               = rule.secondary_key
      primary_connection_string   = rule.primary_connection_string
      secondary_connection_string = rule.secondary_connection_string
    }
  }
  sensitive = true
}

output "namespace_default_keys" {
  description = "Map of namespace key => { primary_connection_string = ..., secondary_connection_string = ... } from the namespace's built-in RootManageSharedAccessKey (only populated when local_authentication_enabled is true). Sensitive: the connection strings are provider-sensitive credentials carrying full manage rights — they land in state and are visible to anyone with state access; prefer scoped rules above over handing out the default key."
  value = {
    for key, ns in azurerm_eventhub_namespace.namespace : key => {
      primary_connection_string   = ns.default_primary_connection_string
      secondary_connection_string = ns.default_secondary_connection_string
    }
  }
  sensitive = true
}
