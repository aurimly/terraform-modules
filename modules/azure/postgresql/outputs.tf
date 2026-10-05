output "server_ids" {
  description = "Map of server key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/<name>\")."
  value       = { for key, server in azurerm_postgresql_flexible_server.server : key => server.id }
}

output "server_names" {
  description = "Map of server key => server name."
  value       = { for key, server in azurerm_postgresql_flexible_server.server : key => server.name }
}

output "server_fqdns" {
  description = "Map of server key => fully qualified domain name (\"<name>.postgres.database.azure.com\") — the host connection strings target."
  value       = { for key, server in azurerm_postgresql_flexible_server.server : key => server.fqdn }
}

output "administrator_logins" {
  description = "Map of server key => administrator login configured on the server."
  value       = { for key, server in azurerm_postgresql_flexible_server.server : key => server.administrator_login }
}

output "database_names" {
  description = "Map of \"<server_key>.<database_key>\" => database name (the provider's id attribute follows the same shape; server_databases consumers read the name directly)."
  value       = { for key, database in azurerm_postgresql_flexible_server_database.database : key => database.name }
}

output "firewall_rule_ids" {
  description = "Map of \"<server_key>.<rule_key>\" => full ARM resource ID of the firewall rule (\"<server_id>/firewallRules/<name>\")."
  value       = { for key, rule in azurerm_postgresql_flexible_server_firewall_rule.rule : key => rule.id }
}
