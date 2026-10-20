output "database_names" {
  description = "Map of database key => database id (e.g. \"(default)\")."
  value       = { for k, d in google_firestore_database.database : k => d.name }
}

output "database_ids" {
  description = "Map of database key => fully qualified database id."
  value       = { for k, d in google_firestore_database.database : k => d.id }
}

output "database_uids" {
  description = "Map of database key => system-generated database uid."
  value       = { for k, d in google_firestore_database.database : k => d.uid }
}
