resource "google_certificate_manager_dns_authorization" "dns_authorization" {
  for_each = var.dns_authorizations

  name            = each.value.name
  project         = each.value.project_id
  location        = each.value.location
  domain          = each.value.domain
  description     = each.value.description
  labels          = each.value.labels
  type            = each.value.type
  deletion_policy = each.value.deletion_policy
}

resource "google_certificate_manager_certificate" "certificate" {
  for_each = var.certificates

  name            = each.value.name
  project         = each.value.project_id
  location        = each.value.location
  description     = each.value.description
  labels          = each.value.labels
  scope           = each.value.scope
  deletion_policy = each.value.deletion_policy

  dynamic "managed" {
    for_each = each.value.managed != null ? [each.value.managed] : []

    content {
      domains = managed.value.domains

      dns_authorizations = [
        for key in managed.value.dns_authorizations : google_certificate_manager_dns_authorization.dns_authorization[key].id
      ]
      issuance_config = managed.value.issuance_config
    }
  }

  dynamic "self_managed" {
    for_each = each.value.self_managed != null ? [each.value.self_managed] : []

    content {
      pem_certificate = self_managed.value.pem_certificate
      pem_private_key = self_managed.value.pem_private_key
    }
  }
}

resource "google_certificate_manager_certificate_map" "map" {
  for_each = var.certificate_maps

  name        = each.value.name
  project     = each.value.project_id
  description = each.value.description
  labels      = each.value.labels
}

locals {
  map_entries = {
    for k, e in var.certificate_map_entries : k => {
      name            = e.name
      project_id      = e.project_id
      description     = e.description
      hostname        = e.hostname
      matcher         = e.matcher
      labels          = e.labels
      map_name        = google_certificate_manager_certificate_map.map[e.map_key].name
      certificate_ids = [for c in e.certificates : google_certificate_manager_certificate.certificate[c].id]
    }
  }
}

resource "google_certificate_manager_certificate_map_entry" "entry" {
  for_each = local.map_entries

  name         = each.value.name
  project      = each.value.project_id
  description  = each.value.description
  map          = each.value.map_name
  hostname     = each.value.hostname
  matcher      = each.value.matcher
  certificates = each.value.certificate_ids
  labels       = each.value.labels
}
