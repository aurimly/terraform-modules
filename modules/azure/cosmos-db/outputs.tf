output "account_ids" {
  description = "Map of account key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/<name>\")."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.id }
}

output "account_names" {
  description = "Map of account key => account name."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.name }
}

output "account_endpoints" {
  description = "Map of account key => the account endpoint (<name>.documents.azure.com)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.endpoint }
}

output "account_write_endpoints" {
  description = "Map of account key => list of write endpoints (one per write region)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.write_endpoints }
}

output "account_read_endpoints" {
  description = "Map of account key => list of read endpoints (one per readable region)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.read_endpoints }
}

output "account_primary_keys" {
  description = "Map of account key => primary key (sensitive — see Notes)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.primary_key }
  sensitive   = true
}

output "account_secondary_keys" {
  description = "Map of account key => secondary key (sensitive — see Notes)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.secondary_key }
  sensitive   = true
}

output "account_primary_readonly_keys" {
  description = "Map of account key => primary read-only key (sensitive — see Notes)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.primary_readonly_key }
  sensitive   = true
}

output "account_primary_sql_connection_strings" {
  description = "Map of account key => primary SQL connection string (sensitive — see Notes)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.primary_sql_connection_string }
  sensitive   = true
}

output "account_primary_mongodb_connection_strings" {
  description = "Map of account key => primary MongoDB connection string (sensitive — see Notes)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => account.primary_mongodb_connection_string }
  sensitive   = true
}

output "account_identity_principal_ids" {
  description = "Map of account key => the system-assigned identity principal ID (identity blocks only — null otherwise)."
  value       = { for key, account in azurerm_cosmosdb_account.account : key => try(account.identity[0].principal_id, null) }
}

output "sql_database_names" {
  description = "Map of \"<account_key>.<db_key>\" => SQL database name."
  value       = { for key, db in azurerm_cosmosdb_sql_database.sql_database : key => db.name }
}

output "sql_database_ids" {
  description = "Map of \"<account_key>.<db_key>\" => full ARM resource ID of the SQL database."
  value       = { for key, db in azurerm_cosmosdb_sql_database.sql_database : key => db.id }
}

output "sql_container_names" {
  description = "Map of \"<account_key>.<db_key>.<container_key>\" => SQL container name."
  value       = { for key, container in azurerm_cosmosdb_sql_container.sql_container : key => container.name }
}

output "sql_container_ids" {
  description = "Map of \"<account_key>.<db_key>.<container_key>\" => full ARM resource ID of the SQL container."
  value       = { for key, container in azurerm_cosmosdb_sql_container.sql_container : key => container.id }
}

output "mongo_database_names" {
  description = "Map of \"<account_key>.<db_key>\" => Mongo database name."
  value       = { for key, db in azurerm_cosmosdb_mongo_database.mongo_database : key => db.name }
}

output "mongo_database_ids" {
  description = "Map of \"<account_key>.<db_key>\" => full ARM resource ID of the Mongo database."
  value       = { for key, db in azurerm_cosmosdb_mongo_database.mongo_database : key => db.id }
}

output "mongo_collection_names" {
  description = "Map of \"<account_key>.<db_key>.<collection_key>\" => Mongo collection name."
  value       = { for key, collection in azurerm_cosmosdb_mongo_collection.mongo_collection : key => collection.name }
}

output "mongo_collection_ids" {
  description = "Map of \"<account_key>.<db_key>.<collection_key>\" => full ARM resource ID of the Mongo collection."
  value       = { for key, collection in azurerm_cosmosdb_mongo_collection.mongo_collection : key => collection.id }
}
