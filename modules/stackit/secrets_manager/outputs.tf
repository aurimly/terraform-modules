output "instances" {
  description = "Map of instance key => object with `instance_id` (UUID) and `id` (\"{project_id},{instance_id}\", the import ID). Users and credentials are managed via stackit/secrets_manager_user."
  value = { for k, i in stackit_secretsmanager_instance.instance : k => {
    instance_id = i.instance_id
    id          = i.id
  } }
}
