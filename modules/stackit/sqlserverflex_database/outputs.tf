output "databases" {
  description = "Map of database key => object with `database_id` (number) and `id` (\"{project_id},{region},{instance_id},{name}\", the import ID). No credentials are exposed here."
  value = { for k, d in stackit_sqlserverflex_database.database : k => {
    database_id = d.database_id
    id          = d.id
  } }
}
