output "server_volume_attaches" {
  description = "Map of server volume attachment key => object with `id` (\"{project_id},{region},{server_id},{volume_id}\", the import ID)."
  value = { for k, a in stackit_server_volume_attach.server_volume_attach : k => {
    id = a.id
  } }
}
