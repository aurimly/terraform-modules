output "server_ids" {
  description = "Map of server key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.Sql/servers/<name>\")."
  value       = { for key, server in azurerm_mssql_server.server : key => server.id }
}

output "server_names" {
  description = "Map of server key => server name — the value the SQL children (databases, firewall rules, failover groups) reference; kept for consumers wiring additional resources against these servers."
  value       = { for key, server in azurerm_mssql_server.server : key => server.name }
}

output "server_fqdns" {
  description = "Map of server key => fully qualified domain name (\"<name>.database.windows.net\") — the host connection strings target."
  value       = { for key, server in azurerm_mssql_server.server : key => server.fully_qualified_domain_name }
}

output "administrator_logins" {
  description = "Map of server key => administrator login configured on the server — Azure generates one when omitted (Entra-only setups); read back after creation."
  value       = { for key, server in azurerm_mssql_server.server : key => server.administrator_login }
}

output "server_identity_principal_ids" {
  description = "Map of server key => principal ID of the server's system-assigned identity, null for servers without one — the identity to grant Key Vault key permissions to in CMK/TDE setups (user-assigned identity principals carry no principal ID here)."
  value       = { for key, server in azurerm_mssql_server.server : key => length(server.identity) > 0 ? server.identity[0].principal_id : null }
}

output "database_ids" {
  description = "Map of \"<server_key>.<database_key>\" => full ARM resource ID of the database (\"<server_id>/databases/<name>\")."
  value       = { for key, database in azurerm_mssql_database.database : key => database.id }
}

output "firewall_rule_ids" {
  description = "Map of \"<server_key>.<rule_key>\" => full ARM resource ID of the firewall rule (\"<server_id>/firewallRules/<name>\")."
  value       = { for key, rule in azurerm_mssql_firewall_rule.rule : key => rule.id }
}

output "elastic_pool_ids" {
  description = "Map of \"<server_key>.<pool_key>\" => full ARM resource ID of the elastic pool (\"<server_id>/elasticPools/<name>\")."
  value       = { for key, pool in azurerm_mssql_elasticpool.pool : key => pool.id }
}

output "failover_group_ids" {
  description = "Map of \"<server_key>.<group_key>\" => full ARM resource ID of the failover group (\"<server_id>/failoverGroups/<name>\")."
  value       = { for key, group in azurerm_mssql_failover_group.failover_group : key => group.id }
}
