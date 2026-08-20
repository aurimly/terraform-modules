resource "google_project" "project" {
  for_each = var.projects

  name                = each.value.name
  project_id          = each.value.project_id
  billing_account     = each.value.billing_account
  org_id              = each.value.folder_id != null ? null : each.value.org_id
  folder_id           = each.value.folder_id
  auto_create_network = each.value.auto_create_network
  deletion_policy     = each.value.deletion_policy
  labels              = each.value.labels
}
