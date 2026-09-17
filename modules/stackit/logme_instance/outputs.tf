output "instances" {
  description = "Map of instance key => object with `instance_id` (UUID), `plan_id`, `dashboard_url` and `id` (\"{project_id},{region},{instance_id}\", the import ID). Connection credentials come from the credential module (stackit/logme_credential)."
  value = { for k, i in stackit_logme_instance.instance : k => {
    instance_id   = i.instance_id
    plan_id       = i.plan_id
    dashboard_url = i.dashboard_url
    id            = i.id
  } }
}
