resource "google_service_account" "service_account" {
  for_each = var.service_accounts

  project                      = coalesce(each.value.project, var.project_id)
  account_id                   = each.value.account_id
  display_name                 = coalesce(each.value.display_name, each.value.account_id)
  description                  = each.value.description
  disabled                     = each.value.disabled
  create_ignore_already_exists = each.value.create_ignore_already_exists
  deletion_policy              = each.value.deletion_policy
}
