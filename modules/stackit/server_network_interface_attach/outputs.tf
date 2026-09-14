output "server_network_interface_attaches" {
  description = "Map of server network interface attachment key => object with `id` (\"{project_id},{region},{server_id},{network_interface_id}\", the import ID)."
  value = { for k, a in stackit_server_network_interface_attach.server_network_interface_attach : k => {
    id = a.id
  } }
}
