output "connections" {
  description = "Map of connection key => object with `connection_id` (UUID) and `id` (\"{project_id},{region},{gateway_id},{connection_id}\", the import ID). No secrets are exposed — the API never returns the pre-shared key."
  value = { for k, c in stackit_vpn_connection.connection : k => {
    connection_id = c.connection_id
    id            = c.id
  } }
}
