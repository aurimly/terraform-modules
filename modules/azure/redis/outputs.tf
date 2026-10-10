output "cache_ids" {
  description = "Map of cache key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Cache/redis/<name>\")."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.id }
}

output "cache_names" {
  description = "Map of cache key => cache name."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.name }
}

output "cache_hostnames" {
  description = "Map of cache key => the cache hostname — the host connection strings target."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.hostname }
}

output "cache_ssl_ports" {
  description = "Map of cache key => the SSL port of the cache."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.ssl_port }
}

output "cache_primary_access_keys" {
  description = "Map of cache key => primary access key (sensitive — see Notes)."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.primary_access_key }
  sensitive   = true
}

output "cache_secondary_access_keys" {
  description = "Map of cache key => secondary access key (sensitive — see Notes)."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.secondary_access_key }
  sensitive   = true
}

output "cache_primary_connection_strings" {
  description = "Map of cache key => primary connection string (sensitive — see Notes)."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.primary_connection_string }
  sensitive   = true
}

output "cache_secondary_connection_strings" {
  description = "Map of cache key => secondary connection string (sensitive — see Notes)."
  value       = { for key, cache in azurerm_redis_cache.cache : key => cache.secondary_connection_string }
  sensitive   = true
}

output "cache_identity_principal_ids" {
  description = "Map of cache key => the system-assigned identity principal ID (identity blocks only — null otherwise)."
  value       = { for key, cache in azurerm_redis_cache.cache : key => try(cache.identity[0].principal_id, null) }
}

output "firewall_rule_ids" {
  description = "Map of \"<cache_key>.<rule_key>\" => full ARM resource ID of the firewall rule (\"<cache_id>/firewallRules/<name>\")."
  value       = { for key, rule in azurerm_redis_firewall_rule.rule : key => rule.id }
}

output "linked_server_ids" {
  description = "Map of linked-server key => full ARM resource ID (\"<target_cache_id>/linkedServers/<name>\")."
  value       = { for key, server in azurerm_redis_linked_server.linked_server : key => server.id }
}

output "linked_server_geo_replicated_primary_host_names" {
  description = "Map of linked-server key => the geo-replicated primary hostname of the pair."
  value       = { for key, server in azurerm_redis_linked_server.linked_server : key => server.geo_replicated_primary_host_name }
}
