output "namespace_ids" {
  description = "Map of namespace key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ServiceBus/namespaces/<name>\")."
  value       = { for key, namespace in azurerm_servicebus_namespace.namespace : key => namespace.id }
}

output "namespace_names" {
  description = "Map of namespace key => namespace name — the host of the namespace's endpoints (<name>.servicebus.windows.net)."
  value       = { for key, namespace in azurerm_servicebus_namespace.namespace : key => namespace.name }
}

output "namespace_endpoints" {
  description = "Map of namespace key => the namespace's endpoint URL (\"https://<name>.servicebus.windows.net:443/\") — the host connection strings target."
  value       = { for key, namespace in azurerm_servicebus_namespace.namespace : key => namespace.endpoint }
}

output "namespace_skus" {
  description = "Map of namespace key => SKU tier (Basic, Standard or Premium) — useful when sibling consumers branch on the namespace's tier."
  value       = { for key, namespace in azurerm_servicebus_namespace.namespace : key => namespace.sku }
}

output "queue_ids" {
  description = "Map of \"<namespace_key>.<queue_key>\" => full ARM resource ID (\"<namespace_id>/queues/<name>\")."
  value       = { for key, queue in azurerm_servicebus_queue.queue : key => queue.id }
}

output "topic_ids" {
  description = "Map of \"<namespace_key>.<topic_key>\" => full ARM resource ID (\"<namespace_id>/topics/<name>\")."
  value       = { for key, topic in azurerm_servicebus_topic.topic : key => topic.id }
}

output "subscription_ids" {
  description = "Map of \"<namespace_key>.<topic_key>.<subscription_key>\" => full ARM resource ID (\"<topic_id>/subscriptions/<name>\")."
  value       = { for key, subscription in azurerm_servicebus_subscription.subscription : key => subscription.id }
}

output "subscription_rule_ids" {
  description = "Map of \"<namespace_key>.<topic_key>.<subscription_key>.<rule_key>\" => full ARM resource ID (\"<subscription_id>/rules/<name>\")."
  value       = { for key, rule in azurerm_servicebus_subscription_rule.rule : key => rule.id }
}

output "namespace_authorization_rule_ids" {
  description = "Map of \"<namespace_key>.<rule_key>\" => full ARM resource ID (\"<namespace_id>/authorizationRules/<name>\")."
  value       = { for key, rule in azurerm_servicebus_namespace_authorization_rule.namespace_rule : key => rule.id }
}

output "queue_authorization_rule_ids" {
  description = "Map of \"<namespace_key>.<queue_key>.<rule_key>\" => full ARM resource ID (\"<queue_id>/authorizationRules/<name>\")."
  value       = { for key, rule in azurerm_servicebus_queue_authorization_rule.queue_rule : key => rule.id }
}

output "topic_authorization_rule_ids" {
  description = "Map of \"<namespace_key>.<topic_key>.<rule_key>\" => full ARM resource ID (\"<topic_id>/authorizationRules/<name>\")."
  value       = { for key, rule in azurerm_servicebus_topic_authorization_rule.topic_rule : key => rule.id }
}

output "namespace_authorization_rule_keys" {
  description = "Map of \"<namespace_key>.<rule_key>\" => { primary_key = ..., secondary_key = ..., primary_connection_string = ..., secondary_connection_string = ... } — the SAS credentials of each namespace-scoped authorization rule. Sensitive: all members are provider-sensitive rights-bearing secrets. They land in state and are visible to anyone with state access — pull them from state or the pipeline, not from logs, and rotate/regenerate them in the Azure portal or CLI."
  value = {
    for key, rule in azurerm_servicebus_namespace_authorization_rule.namespace_rule : key => {
      primary_key                 = rule.primary_key
      secondary_key               = rule.secondary_key
      primary_connection_string   = rule.primary_connection_string
      secondary_connection_string = rule.secondary_connection_string
    }
  }
  sensitive = true
}

output "queue_authorization_rule_keys" {
  description = "Map of \"<namespace_key>.<queue_key>.<rule_key>\" => { primary_key = ..., secondary_key = ..., primary_connection_string = ..., secondary_connection_string = ... } — the SAS credentials of each queue-scoped authorization rule. Sensitive: all members are provider-sensitive rights-bearing secrets. They land in state and are visible to anyone with state access — pull them from state or the pipeline, not from logs, and rotate/regenerate them in the Azure portal or CLI."
  value = {
    for key, rule in azurerm_servicebus_queue_authorization_rule.queue_rule : key => {
      primary_key                 = rule.primary_key
      secondary_key               = rule.secondary_key
      primary_connection_string   = rule.primary_connection_string
      secondary_connection_string = rule.secondary_connection_string
    }
  }
  sensitive = true
}

output "topic_authorization_rule_keys" {
  description = "Map of \"<namespace_key>.<topic_key>.<rule_key>\" => { primary_key = ..., secondary_key = ..., primary_connection_string = ..., secondary_connection_string = ... } — the SAS credentials of each topic-scoped authorization rule. Sensitive: all members are provider-sensitive rights-bearing secrets. They land in state and are visible to anyone with state access — pull them from state or the pipeline, not from logs, and rotate/regenerate them in the Azure portal or CLI."
  value = {
    for key, rule in azurerm_servicebus_topic_authorization_rule.topic_rule : key => {
      primary_key                 = rule.primary_key
      secondary_key               = rule.secondary_key
      primary_connection_string   = rule.primary_connection_string
      secondary_connection_string = rule.secondary_connection_string
    }
  }
  sensitive = true
}

output "namespace_default_keys" {
  description = "Map of namespace key => { primary_connection_string = ..., secondary_connection_string = ... } — the connection strings of the namespace's automatically created RootManageSharedAccessKey rule (full manage/listen/send rights to everything). Sensitive: both members are provider-sensitive secrets. They land in state and are visible to anyone with state access — pull them from state or the pipeline, not from logs; rotation is not managed here (see Notes)."
  value = {
    for key, namespace in azurerm_servicebus_namespace.namespace : key => {
      primary_connection_string   = namespace.default_primary_connection_string
      secondary_connection_string = namespace.default_secondary_connection_string
    }
  }
  sensitive = true
}
