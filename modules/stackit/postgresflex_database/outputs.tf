output "databases" {
  description = "Map of database key => object with `database_id` (UUID) and `id` (\"{project_id},{region},{instance_id},{database_id}\", the import ID)."
  value = { for k, d in stackit_postgresflex_database.database : k => {
    database_id = d.database_id
    id          = d.id
  } }
}
