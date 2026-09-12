output "instances" {
  description = "Map of instance key => object with `instance_id` (UUID), `host` and `port` (write connection info) and `id` (\"{project_id},{region},{instance_id}\", the import ID). Database users and their passwords are managed via stackit/postgresflex_user — no credentials are exposed here."
  value = { for k, i in stackit_postgresflex_instance.instance : k => {
    instance_id = i.instance_id
    host        = i.connection_info.write.host
    port        = i.connection_info.write.port
    id          = i.id
  } }
}
