output "servers" {
  description = "Map of server key => object with `server_id` (UUID), `created_at`, `launched_at`, `updated_at` and `id` (\"{project_id},{region},{server_id}\", the import ID)."
  value = { for k, s in stackit_server.server : k => {
    server_id   = s.server_id
    created_at  = s.created_at
    launched_at = s.launched_at
    updated_at  = s.updated_at
    id          = s.id
  } }
}
