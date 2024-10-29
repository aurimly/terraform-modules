# Project creation
resource "google_project" "project" {
  name                = var.name
  project_id          = var.project_id
  billing_account     = var.billing_account
  org_id              = var.folder_id != "" ? null : var.org_id
  folder_id           = try(var.folder_id, null)
  auto_create_network = try(var.auto_create_network, false)
  deletion_policy     = try(var.deletion_policy, "PREVENT")
  labels              = var.labels == null ? {} : var.labels
}
