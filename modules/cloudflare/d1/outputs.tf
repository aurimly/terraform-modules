output "database_ids" {
  description = "Map of database key => database ID (the D1 UUID used in bindings and wrangler config)."
  value       = { for key, database in cloudflare_d1_database.database : key => database.id }
}

output "database_names" {
  description = "Map of database key => database name."
  value       = { for key, database in cloudflare_d1_database.database : key => database.name }
}
