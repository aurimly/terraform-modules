output "server_ids" {
  description = "Map of server key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DBforMySQL/flexibleServers/<name>\")."
  value       = { for key, server in azurerm_mysql_flexible_server.server : key => server.id }
}

output "server_names" {
  description = "Map of server key => server name — the value the MySQL children (databases, firewall rules) reference; kept for consumers wiring additional resources against these servers."
  value       = { for key, server in azurerm_mysql_flexible_server.server : key => server.name }
}

output "server_fqdns" {
  description = "Map of server key => fully qualified domain name (\"<name>.mysql.database.azure.com\") — the host connection strings target."
  value       = { for key, server in azurerm_mysql_flexible_server.server : key => server.fqdn }
}

output "administrator_logins" {
  description = "Map of server key => administrator login configured on the server."
  value       = { for key, server in azurerm_mysql_flexible_server.server : key => server.administrator_login }
}

output "replica_capacity" {
  description = "Map of server key => maximum number of replicas this server supports (0 when the SKU allows none) — the value replicas stop at."
  value       = { for key, server in azurerm_mysql_flexible_server.server : key => server.replica_capacity }
}

output "database_ids" {
  description = "Map of \"<server_key>.<database_key>\" => full ARM resource ID of the database (the provider's id attribute, \"<server_id>/databases/<name>\")."
  value       = { for key, database in azurerm_mysql_flexible_database.database : key => database.id }
}

output "firewall_rule_ids" {
  description = "Map of \"<server_key>.<rule_key>\" => full ARM resource ID of the firewall rule (\"<server_id>/firewallRules/<name>\")."
  value       = { for key, rule in azurerm_mysql_flexible_server_firewall_rule.rule : key => rule.id }
}
