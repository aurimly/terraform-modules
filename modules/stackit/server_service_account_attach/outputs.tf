output "server_service_account_attaches" {
  description = "Map of server service account attachment key => object with `id` (\"{project_id},{region},{server_id},{service_account_email}\", the import ID)."
  value = { for k, a in stackit_server_service_account_attach.server_service_account_attach : k => {
    id = a.id
  } }
}
