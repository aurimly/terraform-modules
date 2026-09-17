output "instances" {
  description = "Map of instance key => object with `instance_id` (UUID) and `id` (\"{project_id},{region},{instance_id}\", the import ID). This service exposes no connection info on the instance resource — database users (with host and port) are managed via stackit/sqlserverflex_user."
  value = { for k, i in stackit_sqlserverflex_instance.instance : k => {
    instance_id = i.instance_id
    id          = i.id
  } }
}
