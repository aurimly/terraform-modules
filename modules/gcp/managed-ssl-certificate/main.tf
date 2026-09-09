resource "google_compute_managed_ssl_certificate" "certificate" {
  for_each = var.certificates

  name        = each.value.name
  project     = each.value.project_id
  description = each.value.description

  managed {
    domains = each.value.managed.domains
  }
}
