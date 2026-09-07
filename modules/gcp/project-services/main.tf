resource "google_project_service" "service" {
  for_each = var.services

  project                    = each.value.project_id
  service                    = each.value.service
  disable_dependent_services = each.value.disable_dependent_services
  disable_on_destroy         = each.value.disable_on_destroy
}
