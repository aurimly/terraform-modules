output "instances" {
  description = "Map of instance key => object with `instance_id` (UUID) and `id` (\"{project_id},{region},{instance_id}\", the import ID). This service exposes no connection info on the instance resource — credentials/hosts come from the credential module (stackit/rabbitmq_credential)."
  value = { for k, i in stackit_rabbitmq_instance.instance : k => {
    instance_id = i.instance_id
    id          = i.id
  } }
}
