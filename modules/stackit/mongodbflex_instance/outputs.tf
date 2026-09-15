output "instances" {
  description = "Map of instance key => object with `instance_id` and `id` (\"{project_id},{region},{instance_id}\", the import ID). Database users and their passwords are managed via stackit/mongodbflex_user — no credentials are exposed here."
  value = { for k, i in stackit_mongodbflex_instance.instance : k => {
    instance_id = i.instance_id
    id          = i.id
  } }
}
