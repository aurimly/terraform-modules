output "service_accounts" {
  description = "Map of service account key => object with `email` (usable e.g. as an Act-As `subject` in stackit/service_account_role_assignment), `service_account_id` (service account UUID, usable as that module's `resource_id`) and `id` (\"{project_id},{email}\", the import ID)."
  value = { for k, sa in stackit_service_account.service_account : k => {
    email              = sa.email
    service_account_id = sa.service_account_id
    id                 = sa.id
  } }
}
