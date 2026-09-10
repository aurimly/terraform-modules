resource "google_organization_iam_custom_role" "organization_role" {
  for_each = var.organization_roles

  org_id      = each.value.org_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

resource "google_project_iam_custom_role" "project_role" {
  for_each = var.project_roles

  project     = each.value.project_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}
